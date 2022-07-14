#------------------------------------------------------------------------------
# ArgoCD: GitOps + CD
#------------------------------------------------------------------------------
resource "helm_release" "argocd" {
  count      = var.enable_cicd ? 1 : 0
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd[0].id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "4.6.5"
  values = [
    templatefile("chart-values/argo-cd.yaml", {
      argoHost     = "argocd.${local.environment}.${local.private_base_domain}"
      ingressClass = local.private_ingress_class
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
}
