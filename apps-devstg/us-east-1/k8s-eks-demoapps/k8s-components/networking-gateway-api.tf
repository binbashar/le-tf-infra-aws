#------------------------------------------------------------------------------
# Upstream Gateway API CRDs (standard channel)
# -----------------------------------------------------------------------------
# Shared plumbing for every Gateway API data plane in this layer. Kept in its
# own file, rather than inside a specific data plane's, so no single
# implementation becomes load-bearing for the others. Envoy Gateway is the
# only consumer today (kgateway was removed once EG was picked as the
# nginx-ingress replacement); gate the count on the OR of all consumers if
# another one is ever added alongside it.
#
# Applied as individual manifests rather than via a chart: the EG CRD bundle
# blows past etcd's 1 MB-per-Secret limit when helm stores the release, so both
# CRD sets use this same vendored-file + `kubernetes_manifest` for_each pattern.
#
# The bundles are **vendored** under crds/ rather than fetched from GitHub at
# plan time. Three reasons, in order of weight:
#
#   - A `for_each` built from a network read is a `for_each` that can go empty
#     for reasons outside the config. Empty means "destroy everything", and
#     what these keys hold are the Gateway API CRDs — taking every Gateway and
#     HTTPRoute in the cluster down with them.
#   - A version tag pins a URL, not a payload. GitHub release assets are
#     mutable, so the fetched bytes were never guaranteed to be the reviewed
#     ones. A vendored file is pinned by the commit that carries it.
#   - Plan and apply become hermetic: no egress to github.com, so Atlantis and
#     a VPN'd re-spin both stop depending on the release CDN being reachable.
#
# To bump: change the version in terraform.tfvars, then re-vendor — see
# "Re-vendoring the CRD bundles" in README.md.
#
# Install order (enforced via depends_on in networking-envoygateway.tf):
#   1. These upstream Gateway API CRDs (Gateway, HTTPRoute, GatewayClass, …)
#   2. Envoy Gateway's own CRDs (EnvoyProxy, SecurityPolicy, …)
#   3. The Envoy Gateway controller
#------------------------------------------------------------------------------
locals {
  # Split the multi-document YAML into individual docs and keep only valid
  # ones (drops comments, blank chunks, and any stray document separators).
  # Keyed by resource name so the for_each map is stable across plans.
  # The upstream YAML carries a `status: {}` stub on each CRD that the
  # kubernetes_manifest provider forbids (server-managed field), so strip it.
  # Guarded on the flag so the file is only read when Envoy Gateway is on —
  # `file()` on a missing path is an error, not an empty string, which is the
  # loud failure a forgotten re-vendor should produce.
  _gateway_api_crds_body = var.envoy_gateway.enabled ? file(local.gateway_api_crds_path) : ""
  gateway_api_crd_manifests = {
    for doc in [
      for chunk in split("\n---\n", local._gateway_api_crds_body) :
      try(yamldecode(chunk), null)
      ] : doc.metadata.name => {
      for k, v in doc : k => v if k != "status"
    } if doc != null && try(doc.kind, "") != ""
  }
}

resource "kubernetes_manifest" "gateway_api_crds" {
  for_each = local.gateway_api_crd_manifests
  manifest = each.value
}
