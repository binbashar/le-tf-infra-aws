#
# MONITORING: Kube State Metrics
#
resource "helm_release" "kube_state_metrics" {
  name       = "kube-state-metrics"
  namespace  = kubernetes_namespace.monitoring.id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kube-state-metrics"
  version    = "1.2.4"

  values = [
    file("values/kube-state-metrics.yaml")
  ]
}
