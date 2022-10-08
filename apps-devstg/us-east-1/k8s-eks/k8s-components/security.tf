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

#------------------------------------------------------------------------------
# External Secrets Operator: Automated 3rd party Service secrets injection.
#------------------------------------------------------------------------------
resource "helm_release" "external_secrets" {
  count      = var.enable_external_secrets ? 1 : 0
  name       = "external-secrets"
  namespace  = kubernetes_namespace.external-secrets[0].id
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.5.8"
  values = [
    templatefile("chart-values/external-secrets.yaml", {
      roleArn = data.terraform_remote_state.eks-identities.outputs.external_secrets_role_arn
    })
  ]
}

resource "helm_release" "cluster_secrets_manager" {
  count = var.enable_external_secrets ? 1 : 0

  name       = "cluster-secrets-manager"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "raw"
  version    = "0.1.0"
  values = [
    <<-EOF
    resources:
      - apiVersion: external-secrets.io/v1beta1
        kind: ClusterSecretStore
        metadata:
          name: cluster-secrets-manager
        spec:
          provider:
            aws:
              service: SecretsManager
              region: ${var.region}
              auth:
                jwt:
                  serviceAccountRef:
                    name: external-secrets
                    namespace: external-secrets
    EOF
  ]

  depends_on = [helm_release.external_secrets[0]]
}

resource "kubernetes_manifest" "cluster_parameter_store" {
  count = var.enable_external_secrets ? 1 : 0

  name       = "cluster-parameter-store"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "raw"
  version    = "0.1.0"
  values = [
    <<-EOF
    resources:
      apiVersion: external-secrets.io/v1beta1
      kind: ClusterSecretStore
      metadata:
        name: cluster-parameter-store
      spec:
        provider:
          aws:
            service: ParameterStore
            region: ${var.region}
            auth:
              jwt:
                serviceAccountRef:
                  name: external-secrets
                  namespace: external-secrets
    EOF
  ]

  depends_on = [helm_release.external_secrets[0]]
}
