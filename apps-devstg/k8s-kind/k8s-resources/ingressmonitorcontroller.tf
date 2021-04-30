#------------------------------------------------------------------------------
# IngressMonitorController
#------------------------------------------------------------------------------
resource "helm_release" "ingressmonitorcontroller" {
  count      = var.enable_ingressmonitorcontroller ? 1 : 0
  name       = "ingress-monitor-controller"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "ingress-monitor-controller"
  version    = "v2.0.14"
  values     = [file("chart-values/ingress-monitor-controller.yaml")]
}
