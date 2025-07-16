#------------------------------------------------------------------------------
# Vertical Pod Autoscaler: automatic pod vertical autoscaling.
#------------------------------------------------------------------------------
resource "helm_release" "vpa" {
  count      = var.enable_scaling ? 1 : 0
  name       = "vpa"
  namespace  = kubernetes_namespace.monitoring.id
  repository = "https://charts.fairwinds.com/stable"
  chart      = "vpa"
  version    = "0.5.0"
  values     = [file("chart-values/vpa.yaml")]
  depends_on = [helm_release.metrics_server]
}
