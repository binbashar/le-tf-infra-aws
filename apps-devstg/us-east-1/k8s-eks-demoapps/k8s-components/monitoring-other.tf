#------------------------------------------------------------------------------
# Datadog Agent
#------------------------------------------------------------------------------
resource "helm_release" "datadog_agent" {
  count      = var.enable_datadog_agent ? 1 : 0
  name       = "datadog"
  namespace  = kubernetes_namespace.monitoring_other[0].id
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  version    = "3.1.8"
  values = [
    templatefile("chart-values/datadog.yaml", {
      site = "[REGION].datadoghq.com"
      apiKey = "[DATADOG_API_KEY]"
    })
  ]
}
