#------------------------------------------------------------------------------
# Linkerd EmojiVoto Demo Application
#------------------------------------------------------------------------------
# resource "helm_release" "emojivoto" {
#   name       = "emojivoto"
#   namespace  = kubernetes_namespace.argo_cd.id
#   repository = "https://binbashar.github.io/helm-charts/"
#   chart      = "argocd-application"
#   version    = "0.2.0"
#   values     = [file("chart-values/demoapps-emojivoto.yaml")]
#   depends_on = [helm_release.argo_cd]
# }

#------------------------------------------------------------------------------
# Google Microservices Demo
#------------------------------------------------------------------------------
resource "helm_release" "gmd" {
  count      = var.enable_demoapps_gmd ? 1 : 0
  name       = "gmd"
  namespace  = kubernetes_namespace.argo_cd.id
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "argocd-application"
  version    = "0.2.0"
  values = [
    templatefile("chart-values/demoapps-gmd.yaml", local.demoapps.gmd.templateValues)
  ]
  depends_on = [helm_release.argo_cd]
}

#------------------------------------------------------------------------------
# Weave Sock-Shop Microservices Demo
#------------------------------------------------------------------------------
resource "helm_release" "sockshop" {
  count      = var.enable_demoapps_sockshop ? 1 : 0
  name       = "sockshop"
  namespace  = kubernetes_namespace.argo_cd.id
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "argocd-application"
  version    = "0.2.0"
  values = [
    templatefile("chart-values/demoapps-sockshop.yaml", local.demoapps.sockshop.templateValues)
  ]
  depends_on = [helm_release.argo_cd]
}
