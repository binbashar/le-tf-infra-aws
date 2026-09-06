#------------------------------------------------------------------------------
# What this layer knows about the platform underneath it.
#
# Everything here describes objects the `k8s-components` layer provisions, not
# anything a workload owns. It lives in its own file because three workloads now
# reference it — it used to sit in `echo_server.tf` back when that was the only
# one, which made the gateways look like echo-server's property.
#
# Referenced by name rather than by remote state on purpose: `k8s-components`
# exports no outputs. Keep in sync with `networking-envoygateway.tf` there.
#------------------------------------------------------------------------------
locals {
  envoy_gateway_namespace = "envoy-gateway-system"
  private_gateway_name    = "private-gw-eg"
  public_gateway_name     = "public-gw-eg"

  # `public-gw-eg`'s HTTPS listener only accepts HTTPRoutes from namespaces
  # carrying this label — see `local.public_gw_eg_exposure_label` in
  # k8s-components/locals.tf. Without it a public HTTPRoute is created but never
  # attaches, and the app stays unreachable from the internet. The private
  # gateway has no such gate: reaching it already requires the VPN.
  public_exposure_label = { "gateway.binbash.com.ar/public-exposure" = "allowed" }

  # The ECR registry both GitOps apps pull from. It lives in the *shared*
  # account, not this one — the demo images are built once and consumed from
  # every environment.
  #
  # Built from `var.accounts` rather than written out, because the literal
  # carries the shared account ID and this repository is public. `common.tfvars`
  # holds the real value and is gitignored (`*common.tfvars`), which is the only
  # reason account IDs are not already published here; hardcoding one in a layer
  # quietly undoes that. Same reason `config.tf` builds cross-account profiles
  # and bucket names from `var.project` instead of spelling them out.
  ecr_registry = "${var.accounts.shared.id}.dkr.ecr.${var.region}.amazonaws.com"

  #----------------------------------------------------------------------------
  # Conventions every private route in this layer follows, all load-bearing.
  # The same list governs the component routes in `k8s-components/locals.tf`;
  # it is repeated rather than shared because the two layers plan independently.
  #
  #   - **Hostname is one label below the private base domain**, i.e.
  #     `<app>.aws.binbash.com.ar`. That is what the wildcard bound to the
  #     gateway's HTTPS listener covers, and a wildcard matches exactly one
  #     label — the older `<app>.demo.devstg.aws.binbash.com.ar` scheme sat
  #     three labels down and would need a certificate per app.
  #   - **No TLS block, no cert-manager annotation.** The gateway terminates.
  #   - **No HTTP variant.** `private-gw-eg`'s port-80 listener only accepts
  #     routes from its own namespace, where a redirector sends everything to
  #     HTTPS, so attaching here is HTTPS-only by construction.
  #   - **Plain HTTP upstream.** Every backend in this layer serves cleartext
  #     inside the cluster.
  #
  # external-dns watches `gateway-httproute`, so the Route53 record follows from
  # the `hostnames` field with no annotation, and deleting a route deletes the
  # record on the next reconcile (policy `sync`).
  #----------------------------------------------------------------------------
  private_gw_parent_refs = [{
    name      = local.private_gateway_name
    namespace = local.envoy_gateway_namespace
  }]
}
