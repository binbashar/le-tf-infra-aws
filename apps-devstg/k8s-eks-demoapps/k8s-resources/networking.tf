#------------------------------------------------------------------------------
# NETWORKING: Nginx Ingress (Private)
#------------------------------------------------------------------------------
resource "helm_release" "ingress_nginx_private" {
  name       = "ingress-nginx-private"
  namespace  = kubernetes_namespace.ingress_nginx.id
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.19.0"

  values = [ file("chart-values/ingress-nginx-private.yaml") ]
}

#------------------------------------------------------------------------------
# NETWORKING: Nginx Ingress (Public)
#------------------------------------------------------------------------------
# resource "helm_release" "ingress_nginx_public" {
#   name       = "ingress-nginx-public"
#   namespace  = kubernetes_namespace.ingress_nginx.id
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   version    = "3.19.0"

#   values = [ file("chart-values/ingress-nginx-public.yaml") ]
# }

#------------------------------------------------------------------------------
# NETWORKING: External DNS (Private)
#------------------------------------------------------------------------------
resource "helm_release" "external_dns_private" {
  name       = "external-dns-private"
  namespace  = kubernetes_namespace.external_dns.id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "4.6.0"

  values = [ file("chart-values/external-dns-private.yaml") ]

  depends_on = [ helm_release.ingress_nginx_private ]
}

#------------------------------------------------------------------------------
# NETWORKING: External DNS (Public)
#------------------------------------------------------------------------------
# resource "helm_release" "external_dns_public" {
#   name       = "external-dns-public"
#   namespace  = kubernetes_namespace.external_dns.id
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "external-dns"
#   version    = "4.6.0"

#   values = [ file("chart-values/external-dns-public.yaml") ]

#   depends_on = [ helm_release.ingress_nginx_private ]
# }
