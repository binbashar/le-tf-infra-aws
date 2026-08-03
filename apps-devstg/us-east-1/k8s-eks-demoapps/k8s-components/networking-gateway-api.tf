#------------------------------------------------------------------------------
# Upstream Gateway API CRDs (standard channel)
# -----------------------------------------------------------------------------
# Shared plumbing for every Gateway API data plane in this layer — kgateway
# and Envoy Gateway both consume these. Kept in its own file, rather than
# inside one data plane's, so neither becomes load-bearing for the other:
# previously these lived in networking-kgateway.tf gated on
# `var.kgateway.enabled`, which meant disabling kgateway would have pulled the
# CRDs out from under EG. The count is the OR of all consumers.
#
# Fetched from the pinned GitHub release and applied as individual manifests
# rather than via a chart: the EG CRD bundle blows past etcd's 1 MB-per-Secret
# limit when helm stores the release, so both CRD sets use this same
# `data.http` + `kubernetes_manifest` for_each pattern.
#
# Install order (enforced via depends_on in each data plane's file):
#   1. These upstream Gateway API CRDs (Gateway, HTTPRoute, GatewayClass, …)
#   2. The data plane's own CRDs
#   3. The data plane's controller
#------------------------------------------------------------------------------
data "http" "gateway_api_crds" {
  count = (var.kgateway.enabled || var.envoy_gateway.enabled) ? 1 : 0
  url   = local.gateway_api_crds_url
}

locals {
  # Split the multi-document YAML into individual docs and keep only valid
  # ones (drops comments, blank chunks, and any stray document separators).
  # Keyed by resource name so the for_each map is stable across plans.
  # The upstream YAML carries a `status: {}` stub on each CRD that the
  # kubernetes_manifest provider forbids (server-managed field), so strip it.
  _gateway_api_crds_body = try(data.http.gateway_api_crds[0].response_body, "")
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
