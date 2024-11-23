#------------------------------------------------------------------------------
# ArgoCD: GitOps + CD
#------------------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "argocd_admin_password" {
  secret_id = "/k8s-eks-demoapps/argocdserveradminpassword"
}

data "aws_secretsmanager_secret_version" "demo_google_microservices_deploy_key" {
  provider  = aws.shared
  secret_id = "/repositories/demo-google-microservices/deploy_key"
}

data "aws_secretsmanager_secret_version" "le_demo_deploy_key" {
  provider  = aws.shared
  secret_id = "/repositories/le-demo-apps/deploy_key"
}

data "aws_secretsmanager_secret_version" "argocd_slack_notification_app_oauth" {
  provider  = aws.shared
  secret_id = "/notifications/devstg/argocd"
}

resource "helm_release" "argocd" {
  count = var.enable_cicd ? 1 : 0

  name       = "argocd"
  namespace  = kubernetes_namespace.argocd[0].id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.5"
  values = [
    templatefile("chart-values/argo-cd.yaml", {
      argoHost                   = "argocd.${local.platform}.${local.private_base_domain}"
      ingressClass               = local.private_ingress_class,
      enableWebTerminal          = var.argocd.enableWebTerminal,
      enableNotifications        = var.argocd.enableNotifications,
      slackNotificationsAppToken = jsondecode(data.aws_secretsmanager_secret_version.argocd_slack_notifications_app_oauth[0].secret_string)["token"],
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
          argocdServerAdminPassword = data.aws_secretsmanager_secret_version.argocd_admin_password.secret_string
        }
        repositories = {
          demo-google-microservices = {
            name          = "demo-google-microservices"
            project       = "default"
            sshPrivateKey = data.aws_secretsmanager_secret_version.demo_google_microservices_deploy_key.secret_string
            type          = "git"
            url           = "git@github.com:binbashar/demo-google-microservices.git"
          }
          le-demo-apps = {
            name          = "le-demo-apps"
            project       = "default"
            sshPrivateKey = data.aws_secretsmanager_secret_version.le_demo_deploy_key.secret_string
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
  count      = var.enable_argocd_image_updater ? 1 : 0
  name       = "argocd-image-updater"
  namespace  = kubernetes_namespace.argocd[0].id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  version    = "0.11.2"
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
  count = var.enable_argo_rollouts ? 1 : 0

  name       = "argo-rollouts"
  namespace  = kubernetes_namespace.argocd[0].id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = "2.38.0"
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
