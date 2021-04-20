#------------------------------------------------------------------------------
# Cert-Manager: Automatically get Let's Encrypt certificate for your ingress.
#------------------------------------------------------------------------------
# resource "helm_release" "cert_manager" {
#   name       = "cert-manager"
#   namespace  = kubernetes_namespace.cert_manager.id
#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager"
#   version    = "1.1.0"
#   values     = [ file("chart-values/cert-manager.yaml") ]
#   depends_on = [ helm_release.ingress_nginx_private ]
# }

#------------------------------------------------------------------------------
# Cert-Manager Cluster Issuer: Certificate issuer for Binbash domains.
#------------------------------------------------------------------------------
# resource "helm_release" "clusterissuer_binbash" {
#   name       = "clusterissuer-binbash"
#   namespace  = kubernetes_namespace.cert_manager.id
#   repository = "https://binbashar.github.io/helm-charts/"
#   chart      = "cert-manager-clusterissuer"
#   version    = "0.2.0"
#   values     = [ file("chart-values/clusterissuer-binbash.yaml") ]
#   depends_on = [ helm_release.cert_manager ]
# }

#------------------------------------------------------------------------------
# HashiCorp Vault Agent Injector: Automated Vault secrets injection.
#------------------------------------------------------------------------------
# resource "helm_release" "vault" {
#   name       = "vault"
#   namespace  = kubernetes_namespace.vault.id
#   repository = "https://helm.releases.hashicorp.com"
#   chart      = "vault"
#   version    = "0.10.0"
#   values     = [ file("chart-values/vault.yaml") ]
#   depends_on = [
#     helm_release.ingress_nginx_private,
#     helm_release.cert_manager,
#     helm_release.external_dns_private
#   ]
# }
