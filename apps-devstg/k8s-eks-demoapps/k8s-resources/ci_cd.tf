#------------------------------------------------------------------------------
# SECURITY: ArgoCD
#------------------------------------------------------------------------------
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  namespace  = kubernetes_namespace.argo_cd.id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "2.17.4"

  values = [file("chart-values/argo-cd.yaml")]

  depends_on = [
    helm_release.ingress_nginx_private,
    helm_release.cert_manager,
    helm_release.external_dns_private
  ]
}
