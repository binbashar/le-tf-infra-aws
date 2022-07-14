#------------------------------------------------------------------------------
# Cert-Manager: Automatically get Let's Encrypt certificate for your ingress.
#------------------------------------------------------------------------------
resource "helm_release" "certmanager" {
  count      = var.enable_certmanager ? 1 : 0
  name       = "certmanager"
  namespace  = kubernetes_namespace.certmanager[0].id
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.8.0"
  values = [
    templatefile("chart-values/certmanager.yaml", {
      roleArn = data.terraform_remote_state.eks-identities.outputs.certmanager_role_arn
    })
  ]
}

#------------------------------------------------------------------------------
# Cert-Manager Cluster Issuer: Certificate issuer for Binbash domains.
#------------------------------------------------------------------------------
resource "helm_release" "clusterissuer_binbash" {
  count      = var.enable_certmanager ? 1 : 0
  name       = "clusterissuer-binbash"
  namespace  = kubernetes_namespace.certmanager[0].id
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "cert-manager-clusterissuer"
  version    = "0.3.0"
  values = [
    templatefile("chart-values/clusterissuer-binbash.yaml", {
      email  = "info@binbash.com.ar",
      domain = local.public_base_domain,
      region = var.region
    })
  ]
  depends_on = [helm_release.certmanager]
}

#------------------------------------------------------------------------------
# HashiCorp Vault Agent Injector: Automated Vault secrets injection.
#------------------------------------------------------------------------------
resource "helm_release" "vault" {
  count      = var.enable_vault ? 1 : 0
  name       = "vault"
  namespace  = kubernetes_namespace.vault[0].id
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.10.0"
  values = [
    templatefile("chart-values/vault.yaml", {
      vaultAddress = var.vault_address
    })
  ]
}
