#------------------------------------------------------------------------------
# FinOps: Kubernetes Resource Report
#------------------------------------------------------------------------------
# To view the UI run:
#   `k port-forward -n monitoring-tools svc/kube-resource-report 8080:80`
# Then browse this URL:
#   `http://localhost:8080
#------------------------------------------------------------------------------
resource "helm_release" "kube_resource_report" {
  count      = var.cost_optimization.kube_resource_report ? 1 : 0
  name       = "kube-resource-report"
  namespace  = kubernetes_namespace.monitoring_tools[0].id
  repository = "https://rlex.github.io/helm-charts"
  chart      = "kube-resource-report"
  version    = "0.10.1"
}

#------------------------------------------------------------------------------
# FinOps: Cost Analyzer (KubeCost)
#------------------------------------------------------------------------------
# IMPORTANT: for now, Cost-Analyzer and the Prom-Stack can't be deployed at the
# same time. This is because the former, by default, deploys its own Prometheus
# stack. Additional tweaking is necessary to work around this issue.
#------------------------------------------------------------------------------
# To view the UI run:
#   `kubectl port-forward -n kubecost deployment/kubecost-cost-analyzer 9090`
# Then browse this URL:
#   `http://localhost:9090
#------------------------------------------------------------------------------
resource "helm_release" "cost_analyzer" {
  count      = var.cost_optimization.cost_analyzer && !var.enable_prometheus_stack ? 1 : 0
  name       = "cost-analyzer"
  namespace  = kubernetes_namespace.monitoring_tools[0].id
  repository = "https://kubecost.github.io/cost-analyzer/"
  chart      = "cost-analyzer"
  version    = "1.101.3"
}
