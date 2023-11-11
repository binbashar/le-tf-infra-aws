#------------------------------------------------------------------------------
# ArgoCD: GitOps + CD
#------------------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "argocd_slack_app_oauth_token" {
  count     = var.argocd.enabled ? 1 : 0
  provider  = aws.shared
  secret_id = "/notifications/argocd"
}

resource "helm_release" "argocd" {
  count = var.argocd.enabled ? 1 : 0

  name       = "argocd"
  namespace  = kubernetes_namespace.argocd[0].id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.8.3"
  values = [
    templatefile("chart-values/argo-cd.yaml", {
      argoHost                   = "argocd.${local.environment}.${local.private_base_domain}",
      env                        = local.environment,
      ingressClass               = local.private_ingress_class,
      enableWebTerminal          = var.argocd.enableWebTerminal,
      slackNotificationsAppToken = jsondecode(data.aws_secretsmanager_secret_version.argocd_slack_app_oauth_token[0].secret_string)["token"],
      slackNotificationsChannel  = var.argocd.slackNotificationsChannel,
      nodeSelector               = jsonencode({ stack = "argocd" }),
      tolerations = jsonencode([
        {
          key      = "stack",
          operator = "Equal",
          value    = "argocd",
          effect   = "NoSchedule"
        }
      ])
    }),
    # We are using a different approach here because it is very tricky to render
    # properly the multi-line sshPrivateKey using 'templatefile' function
    yamlencode({
      configs = {
        secret = {
          argocdServerAdminPassword = "$2b$12$xAsDJ6xtGby4MKHRbIEwSOrI5z14BUv20vY1d0VLN7Dqq/AC5ZUyG" # TODO pass secret via AWS Secrets Manager
        }
        # To integrate argocd with a private repo
        #repositories = {
        #  demoapp_private_repo = {
        #    name          = "demoapp"
        #    project       = "default"
        #    sshPrivateKey = "argocd.webappRepositoryDeployKey"
        #    type          = "git"
        #    url           = "git@github.com:binbashar/demoapp.git"
        #  }
        #}
      }
    })
  ]

  depends_on = [
    helm_release.alb_ingress,
    helm_release.ingress_nginx_private,
    helm_release.certmanager
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
  version    = "0.8.0"
  values = [
    templatefile("chart-values/argocd-image-updater.yaml", {
      region                   = var.region
      argoHost                 = "argocd.${local.environment}.${local.private_base_domain}",
      repositoryApiUrl         = "${var.accounts.shared.id}.dkr.ecr.${var.region}.amazonaws.com",
      roleArn                  = data.terraform_remote_state.eks-identities.outputs.argo_cd_image_updater_role_arn,
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
  count = var.argo_rollouts.enabled ? 1 : 0

  name       = "argo-rollouts"
  namespace  = kubernetes_namespace.argocd[0].id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = "2.19.0"
  values = [
    templatefile("chart-values/argo-rollouts.yaml", {
      enableDashboard = var.argo_rollouts.dashboard.enabled
      rolloutsHost    = "rollouts.${local.environment}.${local.private_base_domain}"
      ingressClass    = local.private_ingress_class
  })]

  depends_on = [
    helm_release.alb_ingress,
    helm_release.ingress_nginx_private,
    helm_release.certmanager
  ]
}
