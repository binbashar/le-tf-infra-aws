#------------------------------------------------------------------------------
# Cert-Manager: Automatically get Let's Encrypt certificate for your ingress.
#------------------------------------------------------------------------------
resource "helm_release" "cert_manager" {
  count      = var.enable_cert_manager ? 1 : 0
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.id
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.18.2"
  values = [
    templatefile("chart-values/certmanager.yaml",
      {
        roleArn = "arn:aws:iam::${var.accounts.shared.id}:role/demoapps-cert-manager"
      }
    )
  ]
}

#------------------------------------------------------------------------------
# Cert-Manager Cluster Issuer: Certificate issuer for Binbash domains.
#------------------------------------------------------------------------------
resource "helm_release" "clusterissuer_binbash" {
  count      = var.enable_cert_manager ? 1 : 0
  name       = "clusterissuer-binbash"
  namespace  = kubernetes_namespace.cert_manager.id
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "cert-manager-clusterissuer"
  version    = "0.3.0"
  values     = [file("chart-values/clusterissuer-binbash.yaml")]
  depends_on = [helm_release.cert_manager]
}

#------------------------------------------------------------------------------
# HashiCorp Vault Agent Injector: Automated Vault secrets injection.
#------------------------------------------------------------------------------
resource "helm_release" "vault" {
  count      = var.enable_vault ? 1 : 0
  name       = "vault"
  namespace  = kubernetes_namespace.vault.id
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.30.1"
  values     = [file("chart-values/vault.yaml")]
}
