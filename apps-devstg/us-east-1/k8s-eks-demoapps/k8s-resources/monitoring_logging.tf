#------------------------------------------------------------------------------
# k8s-event-logger: watch cluster events and output as logs for further processing.
#------------------------------------------------------------------------------
# resource "helm_release" "k8s_event_logger" {
#   name       = "k8s-event-logger"
#   namespace  = kubernetes_namespace.monitoring.id
#   repository = "https://charts.deliveryhero.io/"
#   chart      = "k8s-event-logger"
#   version    = "1.0.0"
# }

#------------------------------------------------------------------------------
# fluentd + AWS ElasticSearch: collect cluster logs and ship them to AWS ES
#------------------------------------------------------------------------------
resource "helm_release" "fluentd_awses" {
  count      = var.enable_logging_awses ? 1 : 0
  name       = "fluentd-awses"
  namespace  = kubernetes_namespace.monitoring.id
  repository = "https://kokuwaio.github.io/helm-charts"
  chart      = "fluentd-elasticsearch"
  version    = "11.12.0"
  values     = [file("chart-values/fluentd-elasticsearch-aws.yaml")]
}

#------------------------------------------------------------------------------
# fluentd + Self-hosted ElasticSearch: collect cluster logs and ship them to ES
#------------------------------------------------------------------------------
resource "helm_release" "fluentd_selfhosted" {
  count      = var.enable_logging_selfhosted ? 1 : 0
  name       = "fluentd-selfhosted"
  namespace  = kubernetes_namespace.monitoring.id
  repository = "https://kokuwaio.github.io/helm-charts"
  chart      = "fluentd-elasticsearch"
  version    = "11.12.0"
  values     = [file("chart-values/fluentd-elasticsearch-selfhosted.yaml")]
}
