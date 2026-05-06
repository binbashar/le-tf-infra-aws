#------------------------------------------------------------------------------
# Shared ACME ClusterIssuer (`clusterissuer-binbash-aws`)
# -----------------------------------------------------------------------------
# Cluster-scoped LE issuer used by every data plane that runs in this layer
# and needs a wildcard cert against the private base domain. Currently:
#   - kgateway's `private-gw-wildcard` Certificate (private-gw)
#   - envoy-gateway's `private-gw-eg-wildcard` Certificate (private-gw-eg)
#
# Lives in its own helm release (rather than baked into one data plane's TLS
# bundle) so the data planes can be enabled/disabled independently without
# either becoming load-bearing for the other.
#
# DNS01 solver targets the public Route53 zone explicitly. The private zone
# `aws.binbash.com.ar` has no public NS delegation, so public DNS lookups for
# `_acme-challenge.<host>.aws.binbash.com.ar` resolve up the chain to the
# `binbash.com.ar` NS — cert-manager writes the TXT into the public zone
# (where its IRSA role has write perms) and LE's public validators read it
# from there. Pinning `hostedZoneID` to the public zone is what avoids
# cert-manager auto-discovering the longer-suffix-match private zone (where
# it has no perms and would fail).
#
# The bundle is rendered through binbashar/raw rather than `kubernetes_manifest`
# so we sidestep plan-time cert-manager CRD discovery.
#------------------------------------------------------------------------------
locals {
  shared_clusterissuer_name = "clusterissuer-binbash-aws"
}

resource "helm_release" "cluster_issuer_binbash_aws" {
  count = var.certmanager.enabled && (
    (var.kgateway.enabled && var.kgateway.private_gateway.enabled) ||
    (var.envoy_gateway.enabled && var.envoy_gateway.private_gateway.enabled)
  ) ? 1 : 0

  name       = "cluster-issuer-binbash-aws"
  namespace  = kubernetes_namespace.certmanager[0].id
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "raw"
  version    = "0.1.0"

  values = [
    <<-EOF
    resources:
      - apiVersion: cert-manager.io/v1
        kind: ClusterIssuer
        metadata:
          name: ${local.shared_clusterissuer_name}
        spec:
          acme:
            server: https://acme-v02.api.letsencrypt.org/directory
            email: info@binbash.com.ar
            privateKeySecretRef:
              name: ${local.shared_clusterissuer_name}-account-key
            solvers:
              - selector:
                  dnsZones:
                    - ${local.private_base_domain}
                dns01:
                  route53:
                    region: ${var.region}
                    hostedZoneID: ${data.terraform_remote_state.shared-dns.outputs.aws_public_zone_id}
    EOF
  ]

  depends_on = [
    helm_release.certmanager,
  ]
}
