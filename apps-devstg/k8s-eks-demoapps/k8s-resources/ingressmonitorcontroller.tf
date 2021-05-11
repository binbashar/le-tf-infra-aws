#------------------------------------------------------------------------------
# IngressMonitorController
#------------------------------------------------------------------------------
resource "helm_release" "ingressmonitorcontroller" {
  count      = var.enable_ingressmonitorcontroller ? 1 : 0
  name       = "ingress-monitor-controller"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "ingress-monitor-controller"
  version    = "v2.0.14"
  values = [
    templatefile("chart-values/ingress-monitor-controller.yaml",
      {
        uptimerobot_apikey        = lookup(var.imc, "uptimerobot_apikey", "APIKEY")
        uptimerobot_alertcontacts = lookup(var.imc, "uptimerobot_alertcontacts", "ALERTCONTACTS")
      }
    )
  ]
}
