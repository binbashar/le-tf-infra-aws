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
# fluentd: this one uses a different chart which support many more features,
#          however it was not verified to be a working solution yet
#------------------------------------------------------------------------------
resource "helm_release" "fluentd" {
  count      = var.enable_logging ? 1 : 0
  name       = "fluentd"
  namespace  = kubernetes_namespace.monitoring.id
  repository = "https://kokuwaio.github.io/helm-charts"
  chart      = "fluentd-elasticsearch"
  version    = "11.12.0"

  # Enable the following line to use self-hosted ElasticSearch
  # values     = [file("chart-values/fluentd-elasticsearch-selfhosted.yaml")]

  # Enable the following line to use AWS ElasticSearch
  values     = [file("chart-values/fluentd-elasticsearch-aws.yaml")]
}
