#------------------------------------------------------------------------------
# Nginx Ingress (Private): Route network traffic to service in the cluster.
#------------------------------------------------------------------------------
# resource "helm_release" "ingress_nginx_private" {
#   name       = "ingress-nginx-private"
#   namespace  = kubernetes_namespace.ingress_nginx.id
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   version    = "3.19.0"
#   values     = [ file("chart-values/ingress-nginx-private.yaml") ]
# }

#------------------------------------------------------------------------------
# Nginx Ingress (Public): Route network traffic to service in the cluster.
#------------------------------------------------------------------------------
# resource "helm_release" "ingress_nginx_public" {
#   name       = "ingress-nginx-public"
#   namespace  = kubernetes_namespace.ingress_nginx.id
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   version    = "3.19.0"
#   values     = [ file("chart-values/ingress-nginx-public.yaml") ]
# }

#------------------------------------------------------------------------------
# External DNS (Private): Sync ingresses hosts with your DNS server.
#------------------------------------------------------------------------------
# resource "helm_release" "external_dns_private" {
#   name       = "external-dns-private"
#   namespace  = kubernetes_namespace.external_dns.id
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "external-dns"
#   version    = "4.6.0"
#   values     = [ file("chart-values/external-dns-private.yaml") ]
#   depends_on = [ helm_release.ingress_nginx_private ]
# }

#------------------------------------------------------------------------------
# External DNS (Public): Sync ingresses hosts with your DNS server.
#------------------------------------------------------------------------------
# resource "helm_release" "external_dns_public" {
#   name       = "external-dns-public"
#   namespace  = kubernetes_namespace.external_dns.id
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "external-dns"
#   version    = "4.6.0"
#   values     = [ file("chart-values/external-dns-public.yaml") ]
#   depends_on = [ helm_release.ingress_nginx_private ]
# }
