#------------------------------------------------------------------------------
# Kubernetes Dashboard: monitor your cluster resources.
#------------------------------------------------------------------------------
resource "helm_release" "kubernetes_dashboard" {
  count      = var.enable_kubernetes_dashboard ? 1 : 0
  name       = "kubernetes-dashboard"
  namespace  = kubernetes_namespace.monitoring.id
  repository = "https://kubernetes.github.io/dashboard"
  chart      = "kubernetes-dashboard"
  version    = "4.6.0"
  values     = [file("chart-values/kubernetes-dashboard.yaml")]
}

# ------------------------------------------------------------------------------
# Goldilocks: tune up resource requests and limits.
# ------------------------------------------------------------------------------
resource "helm_release" "goldilocks" {
  count      = var.enable_scaling ? 1 : 0
  name       = "goldilocks"
  namespace  = kubernetes_namespace.monitoring.id
  repository = "https://charts.fairwinds.com/stable"
  chart      = "goldilocks"
  version    = "3.2.1"
  values     = [file("chart-values/goldilocks.yaml")]
  depends_on = [helm_release.vpa]
}

#------------------------------------------------------------------------------
# Gatus: Monitor HTTP, TCP, ICMP and DNS.
#------------------------------------------------------------------------------
resource "helm_release" "gatus" {
  count      = var.enable_gatus ? 1 : 0
  name       = "gatus"
  namespace  = kubernetes_namespace.gatus.id
  repository = "https://minicloudlabs.github.io/helm-charts"
  chart      = "gatus"
  version    = "1.1.4"
  values     = [file("chart-values/gatus.yaml")]
}
