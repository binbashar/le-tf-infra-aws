#------------------------------------------------------------------------------
# IngressMonitorController
#------------------------------------------------------------------------------
resource "helm_release" "ingressmonitorcontroller" {
  count      = var.enable_ingressmonitorcontroller ? 1 : 0
  name       = "ingressmonitorcontroller"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "ingressmonitorcontroller"
  version    = "v2.0.14"
  values     = [file("chart-values/ingressmonitorcontroller.yaml")]
}
