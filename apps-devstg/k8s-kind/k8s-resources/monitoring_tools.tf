#------------------------------------------------------------------------------
# Kubernetes Dashboard: monitor your cluster resources.
#------------------------------------------------------------------------------
# resource "helm_release" "kubernetes_dashboard" {
#   name       = "kubernetes-dashboard"
#   namespace  = kubernetes_namespace.monitoring.id
#   repository = "https://kubernetes.github.io/dashboard"
#   chart      = "kubernetes-dashboard"
#   version    = "4.0.0"
#   values     = [ file("chart-values/kubernetes-dashboard.yaml") ]

#   depends_on = [
#     helm_release.ingress_nginx_private,
#     helm_release.cert_manager,
#     helm_release.external_dns_private
#   ]
# }

#------------------------------------------------------------------------------
# Gatus: Monitor HTTP, TCP, ICMP and DNS.
#------------------------------------------------------------------------------
# resource "helm_release" "gatus" {
#   name       = "gatus"
#   namespace  = kubernetes_namespace.gatus.id
#   repository = "https://avakarev.github.io/gatus-chart"
#   chart      = "gatus"
#   version    = "1.1.1"
#   values     = [ file("chart-values/gatus.yaml") ]
# }
