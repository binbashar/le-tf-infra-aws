#------------------------------------------------------------------------------
# Nginx Ingress (Private): Route network traffic to service in the cluster.
#------------------------------------------------------------------------------
resource "helm_release" "ingress_nginx_private" {
  count      = var.enable_private_ingress ? 1 : 0
  name       = "ingress-nginx-private"
  namespace  = kubernetes_namespace.ingress_nginx.id
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.19.0"
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
  version    = "3.19.0"
  values     = [file("chart-values/ingress-nginx-public.yaml")]
}

#------------------------------------------------------------------------------
# External DNS (Private): Sync ingresses hosts with your DNS server.
#------------------------------------------------------------------------------
resource "helm_release" "externaldns_private" {
  count      = var.enable_private_dns_sync ? 1 : 0
  name       = "externaldns-private"
  namespace  = kubernetes_namespace.externaldns.id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "6.5.3"
  values = [
    templatefile("chart-values/externaldns-private.yaml", {
      roleArn = "arn:aws:iam::${var.shared_account_id}:role/appsdevstg-externaldns-private"
    })
  ]
}

#------------------------------------------------------------------------------
# External DNS (Public): Sync ingresses hosts with your DNS server.
#------------------------------------------------------------------------------
resource "helm_release" "externaldns_public" {
  count      = var.enable_public_ingress ? 1 : 0
  name       = "externaldns-public"
  namespace  = kubernetes_namespace.externaldns.id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "4.6.0"
  values = [
    templatefile("chart-values/externaldns-public.yaml", {
      roleArn = "arn:aws:iam::${var.shared_account_id}:role/appsdevstg-externaldns-public"
    })
  ]
}
