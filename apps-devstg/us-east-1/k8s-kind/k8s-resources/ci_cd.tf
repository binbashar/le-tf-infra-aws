#------------------------------------------------------------------------------
# ArgoCD: GitOps + CI/CD
#------------------------------------------------------------------------------
resource "helm_release" "argo_cd" {
  count      = var.enable_cicd ? 1 : 0
  name       = "argo-cd"
  namespace  = kubernetes_namespace.argo_cd.id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "2.17.5"
  values     = [file("chart-values/argo-cd.yaml")]
}
