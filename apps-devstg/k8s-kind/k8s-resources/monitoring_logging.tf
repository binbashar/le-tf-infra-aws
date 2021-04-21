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
# TODO Add fluentd or fluentbit
#------------------------------------------------------------------------------
