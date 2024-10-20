#------------------------------------------------------------------------------
# IngressMonitorController - Static Endpoint
#------------------------------------------------------------------------------
resource "helm_release" "ingressmonitorcontroller-endpoint" {
  count      = var.enable_ingressmonitorcontroller && lookup(var.imc, "example_endpoint", false) ? 1 : 0
  name       = "ingress-monitor-controller-endpoint"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "ingress-monitor-controller-endpoint"
  version    = "0.1.1"
  values     = [file("chart-values/ingress-monitor-controller-endpoint.yaml")]
  depends_on = [helm_release.ingressmonitorcontroller]
}

#------------------------------------------------------------------------------
# IngressMonitorController - Ingress Endpoint
#------------------------------------------------------------------------------
resource "helm_release" "kubernetes_dashboard_imc_endpoint" {
  count      = var.enable_ingressmonitorcontroller && var.enable_kubernetes_dashboard ? 1 : 0
  name       = "kubernetes-dashboard"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "ingress-monitor-controller-endpoint"
  version    = "0.1.1"
  values = [
    templatefile("chart-values/ingress-monitor-controller-ingress-endpoint.yaml",
      {
        name        = "kubernetes-dashboard",
        namespace   = "monitoring",
        ingressName = "kubernetes-dashboard"
      }
    )
  ]
  depends_on = [helm_release.ingressmonitorcontroller, helm_release.kubernetes_dashboard]
}

#------------------------------------------------------------------------------
# ArgoCD emojivoto - Ingress Endpoint
#------------------------------------------------------------------------------
resource "helm_release" "emojivoto_imc_endpoint" {
  count      = var.enable_ingressmonitorcontroller && lookup(var.imc, "emojivoto_endpoint", false) ? 1 : 0
  name       = "emojivoto"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "ingress-monitor-controller-endpoint"
  version    = "0.1.1"
  values = [
    templatefile("chart-values/ingress-monitor-controller-ingress-endpoint.yaml",
      {
        name        = "emojivoto-web",
        namespace   = "demo-emojivoto"
        ingressName = "emojivoto"
      }
    )
  ]
  depends_on = [helm_release.ingressmonitorcontroller, helm_release.emojivoto]
}
