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
      roleArn = data.terraform_remote_state.cluster-identities.outputs.certmanager_role_arn
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
      roleArn = data.terraform_remote_state.cluster-identities.outputs.external_secrets_role_arn
    })
  ]
}

resource "helm_release" "cluster_secrets_manager" {
  count = var.enable_external_secrets ? 1 : 0

  name       = "cluster-secrets-manager"
  namespace  = kubernetes_namespace.external-secrets[0].id
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

# These resources below (cluster_secrets_manager and cluster_parameter_store) need to be commented out and applied in a second step
# The reason behind this can be found in this issue: https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367#issuecomment-1239205722
# and the surounding discussion.
# TODO: Move onto using a raw YAML helm chart as in https://github.com/itscontained/charts/tree/master/itscontained/raw


# resource "kubernetes_manifest" "cluster_parameter_store" {
#   count = var.enable_external_secrets ? 1 : 0

#   manifest = {
#     "apiVersion" = "external-secrets.io/v1beta1"
#     "kind"       = "ClusterSecretStore"
#     "metadata" = {
#       "name" = "cluster-parameter-store"
#     }
#     "spec" = {
#       "provider" = {
#         "aws" = {
#           "service" = "ParameterStore"
#           "region"  = var.region
#           "auth"    = {
#             "jwt" = {
#               "serviceAccountRef" = {
#                 "name"      = "external-secrets",
#                 "namespace" = "external-secrets"
#               }
#             }
#           }
#         }
#       }
#     }
#   }

#   depends_on = [helm_release.external_secrets[0]]
# }
