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
    file("chart-values/kube-state-metrics.yaml")
  ]
}

#
# MONITORING: Node Exporter
#
resource "helm_release" "node_exporter" {
  name       = "node-exporter"
  namespace  = kubernetes_namespace.monitoring.id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "node-exporter"
  version    = "2.2.4"

  values = [
    file("chart-values/node-exporter.yaml")
  ]
}

#
# MONITORING: Kubernetes Dashboard
#
# resource "helm_release" "kubernetes_dashboard" {
#   name       = "kubernetes-dashboard"
#   namespace  = "kube-system"
#   repository = "https://kubernetes.github.io/dashboard"
#   chart      = "kubernetes-dashboard"
#   version    = "4.0.0"

#   values = [
#     file("chart-values/kubernetes-dashboard.yaml")
#   ]
# }
