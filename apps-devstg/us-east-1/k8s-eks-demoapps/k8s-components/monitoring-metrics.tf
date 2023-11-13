#------------------------------------------------------------------------------
# Kube State Metrics: Expose cluster metrics.
#------------------------------------------------------------------------------
resource "helm_release" "kube_state_metrics" {
  count      = var.enable_prometheus_dependencies ? 1 : 0
  name       = "kube-state-metrics"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kube-state-metrics"
  version    = "2.2.24"
  values     = [file("chart-values/kube-state-metrics.yaml")]
}

# ------------------------------------------------------------------------------
# Node Exporter: Expose cluster node metrics.
# ------------------------------------------------------------------------------
resource "helm_release" "node_exporter" {
  count      = var.enable_prometheus_dependencies ? 1 : 0
  name       = "node-exporter"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "node-exporter"
  version    = "2.2.4"
  values     = [file("chart-values/node-exporter.yaml")]
}

#------------------------------------------------------------------------------
# Metrics Server: Expose cluster metrics.
#------------------------------------------------------------------------------
resource "helm_release" "metrics_server" {
  count      = (var.enable_hpa_scaling || var.enable_vpa_scaling) ? 1 : 0
  name       = "metrics-server"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  version    = "5.8.4"
  values     = [file("chart-values/metrics-server.yaml")]
}

#------------------------------------------------------------------------------
# Prometheus Stack: (in-cluster) Prometheus, Grafana, and AlertManager.
#------------------------------------------------------------------------------
resource "helm_release" "kube_prometheus_stack" {
  count      = var.kube_prometheus_stack.enabled && !var.cost_optimization.cost_analyzer ? 1 : 0
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.prometheus[0].id
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "52.1.0"
  values = [templatefile("chart-values/kube-prometheus-stack.yaml",
    {
      private_ingress_class = local.private_ingress_class
      platform              = local.platform
      private_base_domain   = local.private_base_domain
      nodeSelector          = local.tools_nodeSelector
      tolerations           = local.tools_tolerations
    })
  ]
}
