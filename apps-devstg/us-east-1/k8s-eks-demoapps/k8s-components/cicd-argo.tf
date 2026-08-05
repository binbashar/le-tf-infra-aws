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

data "aws_secretsmanager_secret_version" "le_demo_deploy_key" {
  count     = var.argocd.enabled ? 1 : 0
  provider  = aws.shared
  secret_id = "/repositories/le-demo-apps/deploy_key"
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
  #   - 8.0.0 is the Argo CD v2 -> v3 jump. No state to migrate here: no
  #     Applications exist, and the admin password and both repository
  #     credentials are re-rendered from Secrets Manager on every apply.
  version = "10.2.3"
  values = [
    templatefile("chart-values/argo-cd.yaml", {
      argoHost                   = local.argocd_host,
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
        repositories = {
          demo-google-microservices = {
            name          = "demo-google-microservices"
            project       = "default"
            sshPrivateKey = data.aws_secretsmanager_secret_version.demo_google_microservices_deploy_key[0].secret_string
            type          = "git"
            url           = "git@github.com:binbashar/demo-google-microservices.git"
          }
          le-demo-apps = {
            name          = "le-demo-apps"
            project       = "default"
            sshPrivateKey = data.aws_secretsmanager_secret_version.le_demo_deploy_key[0].secret_string
            type          = "git"
            url           = "git@github.com:binbashar/le-demo-apps.git"
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
# ArgoCD exposure: HTTPRoute on the platform-shared `private-gw-eg`.
#
# Replaces the nginx Ingress the chart used to render. Three things moved with
# it:
#
#   - TLS. The gateway's HTTPS listener terminates with the
#     `*.aws.binbash.com.ar` wildcard, so the per-app cert-manager Certificate
#     the Ingress used to request is gone.
#   - The hostname. It was `argocd.demo.devstg.aws.binbash.com.ar`, three
#     labels below the private base domain — which the single-label wildcard
#     does not cover, so it would have needed its own certificate. Flattened to
#     `argocd.aws.binbash.com.ar`, matching how echo-server names itself. Safe
#     to change because ArgoCD had been `enabled = false`, so no one held the
#     old URL.
#   - The backend protocol. The Ingress annotated
#     `nginx.ingress.kubernetes.io/backend-protocol: HTTPS`; the equivalent
#     here is `server.insecure` in the chart values, which drops argocd-server
#     to plain HTTP instead of teaching the gateway to re-encrypt.
#
# There is no HTTP variant: `private-gw-eg`'s port-80 listener only accepts
# routes from its own namespace, and the redirector living there sends
# everything to HTTPS.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "argocd_route_eg" {
  count = var.argocd.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd-server"
      namespace = kubernetes_namespace.argocd[0].id
    }
    spec = {
      parentRefs = [{
        name      = kubernetes_manifest.private_gateway_eg[0].manifest.metadata.name
        namespace = kubernetes_namespace.envoy_gateway[0].id
      }]
      hostnames = [local.argocd_host]
      rules = [{
        backendRefs = [{
          # The chart names this `<release>-server`. Port 80 is the cleartext
          # one; it only serves traffic because of `server.insecure`.
          name = "argocd-server"
          port = 80
        }]
      }]
    }
  }

  depends_on = [
    helm_release.argocd,
  ]
}

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
  version    = "2.40.8"
  values = [
    templatefile("chart-values/argo-rollouts.yaml", {
      enableDashboard = var.argocd.rollouts.dashboard.enabled,
      rolloutsHost    = "rollouts.${local.platform}.${local.private_base_domain}",
      ingressClass    = local.private_ingress_class,
      nodeSelector    = local.tools_nodeSelector,
      tolerations     = local.tools_tolerations
    })
  ]

  depends_on = [
    helm_release.alb_ingress,
    helm_release.ingress_nginx_private,
    helm_release.certmanager
  ]
}
