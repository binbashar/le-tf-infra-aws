#==============================================================================
# Demo apps
#==============================================================================
# Per-app toggles for the workloads in this layer. Set `enabled = false` to
# tear down an app on the next apply. The kgateway and Envoy Gateway HTTPRoutes
# attached to echo-server come and go with `echo_server.enabled`.
#
# google_microservices_dev and emojivoto are ArgoCD Applications and depend on
# the argocd CRDs, which the k8s-components layer ships only when its
# `argocd.enabled = true`. They default to `false` here so this layer plans
# cleanly without argocd; flip them to `true` once you've enabled argocd in
# k8s-components.
demo_apps = {
  echo_server = {
    enabled = true
  }
  google_microservices_dev = {
    enabled = false
  }
  emojivoto = {
    enabled = false
  }
}
