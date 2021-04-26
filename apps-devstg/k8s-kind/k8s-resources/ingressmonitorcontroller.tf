#------------------------------------------------------------------------------
# IngressMonitorController
#------------------------------------------------------------------------------
resource "helm_release" "ingressmonitorcontroller" {
  count     = var.enable_ingressmonitorcontroller ? 1 : 0
  name      = "ingressmonitorcontroller"
  namespace = kubernetes_namespace.metallb.id
  #repository = "https://github.com/binbashar/helm-charts"
  repository = "/home/lgallard/git/binbash/helm-charts/charts/"
  chart      = "ingressmonitorcontroller"
  version    = "v2.0.14"
  values     = [file("chart-values/ingressmonitorcontroller.yaml")]
}
