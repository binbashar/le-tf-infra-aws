#------------------------------------------------------------------------------
# ArgoCD: GitOps + CI/CD
#------------------------------------------------------------------------------
resource "helm_release" "argocd" {
  count      = var.enable_cicd ? 1 : 0
  name       = "argo-cd"
  namespace  = kubernetes_namespace.argocd.id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "4.5.7"
  values     = [file("chart-values/argo-cd.yaml")]
}

#------------------------------------------------------------------------------
# ArgoCD Image Updater: GitOps + CI/CD
#------------------------------------------------------------------------------
resource "helm_release" "argocd_image_updater" {
  count      = var.enable_argocd_image_updated ? 1 : 0
  name       = "argo-cd-image-updater"
  namespace  = kubernetes_namespace.argocd.id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  version    = "0.7.0"
  values     = [file("chart-values/argo-cd-image-updater.yaml")]
}
