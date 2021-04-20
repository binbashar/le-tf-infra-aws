#------------------------------------------------------------------------------
# Kube State Metrics: Expose cluster metrics.
#------------------------------------------------------------------------------
# resource "helm_release" "kube_state_metrics" {
#   name       = "kube-state-metrics"
#   namespace  = kubernetes_namespace.monitoring.id
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "kube-state-metrics"
#   version    = "1.2.4"
#   values     = [ file("chart-values/kube-state-metrics.yaml") ]
# }

#------------------------------------------------------------------------------
# Node Exporter: Expose cluster node metrics.
#------------------------------------------------------------------------------
# resource "helm_release" "node_exporter" {
#   name       = "node-exporter"
#   namespace  = kubernetes_namespace.monitoring.id
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "node-exporter"
#   version    = "2.2.4"
#   values     = [ file("chart-values/node-exporter.yaml") ]
# }

#------------------------------------------------------------------------------
# Metrics Server: Expose cluster metrics.
#------------------------------------------------------------------------------
# resource "helm_release" "metrics_server" {
#   name       = "metrics-server"
#   namespace  = kubernetes_namespace.monitoring.id
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "metrics-server"
#   version    = "5.8.4"
#   values     = [ file("chart-values/metrics-server.yaml") ]
# }
