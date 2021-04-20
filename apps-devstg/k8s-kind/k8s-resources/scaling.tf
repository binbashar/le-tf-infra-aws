#------------------------------------------------------------------------------
# Vertical Pod Autoscaler: automatic pod vertical autoscaling.
#------------------------------------------------------------------------------
# resource "helm_release" "vpa" {
#   name       = "vpa"
#   namespace  = kubernetes_namespace.monitoring.id
#   repository = "https://charts.fairwinds.com/stable"
#   chart      = "vpa"
#   version    = "0.3.2"
#   values     = [ file("chart-values/vpa.yaml") ]
#   depends_on = [ helm_release.metrics_server ]
# }

#------------------------------------------------------------------------------
# Goldilocks: tune up resource requests and limits.
#------------------------------------------------------------------------------
# resource "helm_release" "goldilocks" {
#   name       = "goldilocks"
#   namespace  = kubernetes_namespace.monitoring.id
#   repository = "https://charts.fairwinds.com/stable"
#   chart      = "goldilocks"
#   version    = "3.2.1"
#   values     = [ file("chart-values/goldilocks.yaml") ]
#   depends_on = [ helm_release.vpa ]
# }
