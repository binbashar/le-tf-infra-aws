#==============================================================================
# Demo apps
#==============================================================================
# Per-app toggles for the workloads in this layer. Set `enabled = false` to
# tear down an app on the next apply. The Envoy Gateway HTTPRoute attached to
# echo-server comes and goes with `echo_server.enabled`.
#
# google_microservices_dev and emojivoto are ArgoCD Applications: the resources
# are `kubernetes_manifest`, which validates against the live API at *plan*
# time, so they cannot even be planned before `k8s-components` has installed
# argocd. Setting either to `true` here therefore commits the whole layer to
# running after that one — which is the documented order anyway.
#
# What each needs on top of `argocd.enabled` in k8s-components:
#   - emojivoto                → `argocd.rollouts.enabled` (its workloads are
#                                `kind: Rollout`).
#   - google_microservices_dev → `external_secrets.enabled`, plus the `secrets`
#                                layer applied, or `paymentservice` never
#                                starts.
demo_apps = {
  echo_server = {
    enabled = true
    # Adds echo-server.binbash.com.ar via the public Envoy Gateway, on top of
    # the private hostname. Depends on
    # `envoy_gateway.public_gateway.enabled` in k8s-components.
    public_endpoint = true
    # Restricts that hostname to `echo_server_public_allowed_cidrs` inside
    # Envoy — the per-application filtering an nginx `whitelist-source-range`
    # annotation performs. Set the list in allowlist.local.auto.tfvars.
    restrict_public_access = true
  }
  google_microservices_dev = {
    enabled = true
  }
  emojivoto = {
    enabled = true
  }
}
