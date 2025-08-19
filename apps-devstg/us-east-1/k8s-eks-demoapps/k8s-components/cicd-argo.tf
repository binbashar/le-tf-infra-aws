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
  version    = "7.9.1"
  values = [
    templatefile("chart-values/argo-cd.yaml", {
      argoHost                   = "argocd.${local.platform}.${local.private_base_domain}",
      ingressClass               = local.private_ingress_class,
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
  version    = "0.12.3"
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
  version    = "2.39.6"
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
