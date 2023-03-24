#------------------------------------------------------------------------------
# FinOps: Kubernetes Resource Report
#------------------------------------------------------------------------------
# To view the UI run:
#   `k port-forward -n monitoring-tools svc/kube-resource-report 8080:80`
# Then browse this URL:
#   `http://localhost:8080
#------------------------------------------------------------------------------
resource "helm_release" "kube_resource_report" {
  count      = var.enable_cost_optimization_tools ? 1 : 0
  name       = "kube-resource-report"
  namespace  = kubernetes_namespace.monitoring_tools[0].id
  repository = "https://rlex.github.io/helm-charts"
  chart      = "kube-resource-report"
  version    = "0.10.1"
}
