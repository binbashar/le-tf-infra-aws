#------------------------------------------------------------------------------
# ArgoCD: GitOps + CD
#------------------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "argocd_admin_password" {
  count     = var.argocd.enabled ? 1 : 0
  secret_id = "/k8s-eks-demoapps/argocdserveradminpassword"
}

data "aws_secretsmanager_secret_version" "demo_google_microservices_deploy_key" {
  count     = var.argocd.enabled ? 1 : 0
  provider  = aws.shared
  secret_id = "/repositories/demo-google-microservices/deploy_key"
}

data "aws_secretsmanager_secret_version" "argocd_slack_notifications_app_oauth" {
  count     = var.argocd.enabled && var.argocd.enableNotifications ? 1 : 0
  provider  = aws.shared
  secret_id = "/notifications/devstg/argocd"
}

resource "helm_release" "argocd" {
  count = var.argocd.enabled ? 1 : 0

  name       = "argocd"
  namespace  = kubernetes_namespace.argocd[0].id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  # 10.2.3 -> Argo CD v3.5.0. Jumped from 7.9.1 (v2.14.11) after confirming the
  # Envoy Gateway integration worked on the old version, so a routing problem
  # and an upgrade problem could not be confused for each other.
  #
  # Breaking changes across that range that actually touch this config:
  #   - 10.0.0 flips `global.networkPolicy.create` false -> true, so the chart
  #     now ships NetworkPolicies. The one guarding argocd-server has to admit
  #     the Envoy pods from `envoy-gateway-system` or the HTTPRoute below
  #     resolves to a black hole. Left at the upstream default deliberately —
  #     it is the security-sensible setting and the integration is verified
  #     against it rather than around it.
  #   - 9.0.0 dropped `configs.params` defaults from values.yaml but kept the
  #     override interface, so `server.insecure` still applies as written.
  #   - 9.1.0's redis-ha selector breakage does not apply: this runs the
  #     single-replica redis, not redis-ha.
  #   - 8.0.0 is the Argo CD v2 -> v3 jump. Nothing to migrate: the admin
  #     password and the repository credential are re-rendered from Secrets
  #     Manager on every apply, and the Applications live in `k8s-workloads`,
  #     which is applied after this.
  version = "10.2.3"
  values = [
    templatefile("chart-values/argo-cd.yaml", {
      parentRefs                 = jsonencode(local.private_gw_parent_refs),
      argoHost                   = local.argocd_host,
      argocdHost                 = local.argocd_host,
      enableWebTerminal          = var.argocd.enableWebTerminal,
      enableNotifications        = var.argocd.enableNotifications,
      slackNotificationsAppToken = var.argocd.enableNotifications ? jsondecode(data.aws_secretsmanager_secret_version.argocd_slack_notifications_app_oauth[0].secret_string)["slack_app_oauth_token"] : "",
      slackNotificationsChannel  = local.argocd_slack_notifications_channel,
      nodeSelector               = local.tools_nodeSelector,
      tolerations                = local.tools_tolerations
    }),
    # We are using a different approach here because it is very tricky to render
    # properly the multi-line sshPrivateKey using 'templatefile' function
    yamlencode({
      configs = {
        secret = {
          # Get argocd admin password from AWS Secrets Manager
          argocdServerAdminPassword = data.aws_secretsmanager_secret_version.argocd_admin_password[0].secret_string
        }
        # One entry, for the one repository that needs a credential.
        #
        # `le-demo-apps` used to be here too, with its own deploy key from
        # Secrets Manager. That repository is public — it is published as
        # Leverage reference material — and its deploy key was deleted from
        # GitHub when it was published, leaving an orphaned key in Secrets
        # Manager and an Argo CD credential that could only fail. The
        # emojivoto Application reads it anonymously over HTTPS instead; see
        # the note on `repoURL` in `k8s-workloads/emojivoto.tf`.
        repositories = {
          demo-google-microservices = {
            name          = "demo-google-microservices"
            project       = "default"
            sshPrivateKey = data.aws_secretsmanager_secret_version.demo_google_microservices_deploy_key[0].secret_string
            type          = "git"
            url           = "git@github.com:binbashar/demo-google-microservices.git"
          }
        }
      }
    })
  ]

  depends_on = [
    helm_release.alb_ingress,
    kubernetes_manifest.private_gateway_eg,
    helm_release.certmanager
  ]
}

#------------------------------------------------------------------------------
# ArgoCD exposure. Replaces the nginx Ingress the chart used to render; see
# `local.private_gw_parent_refs` in locals.tf for the conventions every private
# route follows. Three things moved with the Ingress, not one:
#
#   - TLS. It requested its own cert-manager Certificate; the gateway's HTTPS
#     listener already terminates with the `*.aws.binbash.com.ar` wildcard.
#   - The hostname. `argocd.demo.devstg.aws.binbash.com.ar` sat three labels
#     below the private base domain, which that wildcard does not cover.
#   - The backend protocol. `nginx.ingress.kubernetes.io/backend-protocol:
#     HTTPS` became `server.insecure` in the chart values — argocd-server drops
#     to plain HTTP rather than the gateway learning to re-encrypt.

#------------------------------------------------------------------------------
# ArgoCD Image Updater
#------------------------------------------------------------------------------
resource "helm_release" "argocd_image_updater" {
  count      = var.argocd.image_updater.enabled ? 1 : 0
  name       = "argocd-image-updater"
  namespace  = kubernetes_namespace.argocd[0].id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  version    = "0.14.0"
  values = [
    templatefile("chart-values/argocd-image-updater.yaml", {
      region                   = var.region
      argoHost                 = "argocd.${local.platform}.${local.private_base_domain}",
      repositoryApiUrl         = "${var.accounts.shared.id}.dkr.ecr.${var.region}.amazonaws.com",
      roleArn                  = data.terraform_remote_state.cluster-identities.outputs.argo_cd_image_updater_role_arn,
      nodeSelector             = local.tools_nodeSelector,
      tolerations              = local.tools_tolerations,
      gitCommitUser            = "binbash-machine-user"
      gitCommitMail            = "leverage-aws+machine-user@binbash.com.ar"
      gitCommitMessageTemplate = <<-TMP
      Build: Image update for application '{{ .AppName }}'

          {{ range .AppChanges -}}
          Update image {{ .Image }} from '{{ .OldTag }}' to '{{ .NewTag }}'
          {{ end -}}
      TMP
    })
  ]

  depends_on = [
    helm_release.argocd
  ]
}

#------------------------------------------------------------------------------
# Argo Rollouts
#------------------------------------------------------------------------------
resource "helm_release" "argo_rollouts" {
  count = var.argocd.rollouts.enabled ? 1 : 0

  name       = "argo-rollouts"
  namespace  = kubernetes_namespace.argocd[0].id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = "2.41.1"
  values = [
    templatefile("chart-values/argo-rollouts.yaml", {
      parentRefs      = jsonencode(local.private_gw_parent_refs),
      rolloutsHost    = "rollouts.${local.private_base_domain}",
      enableDashboard = var.argocd.rollouts.dashboard.enabled,
      nodeSelector    = local.tools_nodeSelector,
      tolerations     = local.tools_tolerations
    })
  ]

  depends_on = [
    helm_release.alb_ingress,
    kubernetes_manifest.private_gateway_eg,
    helm_release.certmanager
  ]
}

#------------------------------------------------------------------------------
# Argo Rollouts dashboard exposure. The old Ingress carried
# `nginx.ingress.kubernetes.io/backend-protocol: HTTPS`, copy-pasted from
# ArgoCD and wrong here — the dashboard serves plain HTTP on 3100 and never had
# TLS of its own. It also pinned `paths: [/rollouts]`; with a hostname to
# itself there is no sub-path to carve out, so this routes the root. The app
# still self-redirects to `/rollouts/`, which is its own doing.
