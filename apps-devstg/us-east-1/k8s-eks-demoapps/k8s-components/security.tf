#------------------------------------------------------------------------------
# Cert-Manager: Automatically get Let's Encrypt certificate for your ingress.
#------------------------------------------------------------------------------
resource "helm_release" "certmanager" {
  count      = var.certmanager.enabled ? 1 : 0
  name       = "certmanager"
  namespace  = kubernetes_namespace.certmanager[0].id
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.21.1"
  values = [
    templatefile("chart-values/certmanager.yaml", {
      roleArn      = data.terraform_remote_state.cluster-identities.outputs.certmanager_role_arn
      nodeSelector = local.tools_nodeSelector
      tolerations  = local.tools_tolerations
    })
  ]
}

#------------------------------------------------------------------------------
# Cert-Manager Cluster Issuer: Certificate issuer for Binbash domains.
#------------------------------------------------------------------------------
resource "helm_release" "clusterissuer_binbash" {
  count      = var.certmanager.enabled ? 1 : 0
  name       = "clusterissuer-binbash"
  namespace  = kubernetes_namespace.certmanager[0].id
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "cert-manager-clusterissuer"
  version    = "0.3.0"
  values = [
    templatefile("chart-values/clusterissuer-binbash.yaml", {
      acmeServer = local.acme_server,
      email      = "info@binbash.com.ar",
      domain     = local.public_base_domain,
      region     = var.region
    })
  ]
  depends_on = [helm_release.certmanager]
}

#------------------------------------------------------------------------------
# External Secrets Operator: Automated 3rd party Service secrets injection.
#------------------------------------------------------------------------------
resource "helm_release" "external_secrets" {
  count      = var.external_secrets.enabled ? 1 : 0
  name       = "external-secrets"
  namespace  = kubernetes_namespace.external-secrets[0].id
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.20.4"
  values = [
    templatefile("chart-values/external-secrets.yaml", {
      roleArn = data.terraform_remote_state.cluster-identities.outputs.external_secrets_role_arn
    })
  ]
}

resource "helm_release" "cluster_secrets_manager" {
  count = var.external_secrets.enabled ? 1 : 0

  name       = "cluster-secrets-manager"
  namespace  = kubernetes_namespace.external-secrets[0].id
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "raw"
  version    = "0.1.0"
  # `v1`, not `v1beta1`. ESO ships both versions in the CRD, but from 0.17 on
  # `v1beta1` is declared with `served: false` — it exists only so objects
  # stored under it can be read back after conversion. Helm resolves the kind
  # against the API server's discovery, so the release fails outright with
  # `no matches for kind "ClusterSecretStore" in version
  # "external-secrets.io/v1beta1"`, and it fails *at apply*: nothing in a plan
  # looks at the chart's rendered manifest. Found on the first live apply of
  # this component since the chart was pinned to 0.20.4.
  values = [
    <<-EOF
    resources:
      - apiVersion: external-secrets.io/v1
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

# These resources below (cluster_parameter_store) need to be commented out and applied in a second step
# The reason behind this can be found in this issue: https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367#issuecomment-1239205722
# and the surrounding discussion.
# TODO: Move onto using a raw YAML helm chart as in https://github.com/itscontained/charts/tree/master/itscontained/raw


# resource "kubernetes_manifest" "cluster_parameter_store" {
#   count = var.external_secrets.enabled ? 1 : 0

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
