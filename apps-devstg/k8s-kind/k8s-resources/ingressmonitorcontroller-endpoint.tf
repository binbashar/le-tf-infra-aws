#------------------------------------------------------------------------------
# IngressMonitorController - Endpoint
#------------------------------------------------------------------------------
resource "helm_release" "ingressmonitorcontroller-endpoint" {
  count      = var.enable_ingressmonitorcontroller ? 1 : 0
  name       = "ingress-monitor-controller-endpoint"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "ingress-monitor-controller-endpoint"
  version    = "0.1.0"
  values     = [file("chart-values/ingress-monitor-controller-endpoint.yaml")]
  depends_on = [helm_release.ingressmonitorcontroller]
}
