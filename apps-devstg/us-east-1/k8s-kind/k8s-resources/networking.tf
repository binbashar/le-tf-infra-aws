#------------------------------------------------------------------------------
# Nginx Ingress (Private): Route network traffic to service in the cluster.
#------------------------------------------------------------------------------
resource "helm_release" "ingress_nginx_private" {
  count      = var.enable_private_ingress ? 1 : 0
  name       = "ingress-nginx-private"
  namespace  = kubernetes_namespace.ingress_nginx.id
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.41.0"
  values     = [file("chart-values/ingress-nginx-private.yaml")]
}

#------------------------------------------------------------------------------
# Nginx Ingress (Public): Route network traffic to service in the cluster.
#------------------------------------------------------------------------------
resource "helm_release" "ingress_nginx_public" {
  count      = var.enable_public_ingress ? 1 : 0
  name       = "ingress-nginx-public"
  namespace  = kubernetes_namespace.ingress_nginx.id
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.41.0"
  values     = [file("chart-values/ingress-nginx-public.yaml")]
}

#------------------------------------------------------------------------------
# External DNS (Private): Sync ingresses hosts with your DNS server.
#------------------------------------------------------------------------------
resource "helm_release" "external_dns_private" {
  count      = var.enable_private_dns_sync ? 1 : 0
  name       = "external-dns-private"
  namespace  = kubernetes_namespace.external_dns.id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "4.6.0"
  values = [
    templatefile("chart-values/externaldns-private.yaml",
      {
        roleArn = "arn:aws:iam::${var.accounts.shared.id}:role/demoapps-external-dns-private"
      }
    )
  ]
}

#------------------------------------------------------------------------------
# External DNS (Public): Sync ingresses hosts with your DNS server.
#------------------------------------------------------------------------------
resource "helm_release" "external_dns_public" {
  count      = var.enable_public_ingress ? 1 : 0
  name       = "external-dns-public"
  namespace  = kubernetes_namespace.external_dns.id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "4.6.0"
  values = [
    templatefile("chart-values/externaldns-public.yaml",
      {
        roleArn = "arn:aws:iam::${var.accounts.shared.id}:role/demoapps-external-dns-public"
      }
    )
  ]
}
