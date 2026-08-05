#------------------------------------------------------------------------------
# Private HTTPRoutes — everything published on the shared `private-gw-eg`
# -----------------------------------------------------------------------------
# One entry per hostname. This exists as a single table rather than a route
# resource next to each component because "what is reachable on the private
# gateway?" is an operational question that used to require grepping seven
# chart-values files, and because seven near-identical 20-line manifests drift:
# one of them ends up with a different `sectionName` or a stale port and nobody
# notices until it 404s.
#
# The *why* for each component still lives in that component's file — this
# table only owns the plumbing. Adding a row is the whole job of exposing
# something privately; there is no second place to touch.
#
# Conventions baked in here, all of them load-bearing:
#
#   - **Hostname is the map key**, resolved as `<key>.<private base domain>`.
#     One label below `aws.binbash.com.ar`, which is what the wildcard cert
#     bound to the gateway's HTTPS listener covers. The old
#     `<app>.demo.devstg.aws.binbash.com.ar` scheme sat three labels down and a
#     single-label wildcard does not match it, so every component would have
#     needed a certificate of its own. Flattening is what makes one shared cert
#     work for all of them.
#   - **No TLS block, no cert-manager annotation.** The gateway terminates.
#   - **No HTTP variant.** `private-gw-eg`'s port-80 listener only accepts
#     routes from its own namespace, and the redirector living there sends
#     everything to HTTPS. Attaching here means HTTPS-only by construction.
#   - **Plain HTTP upstream.** Every backend below serves cleartext inside the
#     cluster. The one that did not — argocd-server — was told to stop
#     (`server.insecure`) rather than have the gateway re-encrypt; see
#     chart-values/argo-cd.yaml.
#
# external-dns watches `gateway-httproute`, so the Route53 record follows from
# the `hostnames` field with no extra annotation. Removing a row deletes the
# record on the next reconcile (policy `sync`).
#------------------------------------------------------------------------------
locals {
  # `enabled` mirrors the count expression of the helm_release that provides
  # `service`. Keep the two in sync — a row whose backend is not installed
  # produces an HTTPRoute stuck at `ResolvedRefs=False` and a Route53 record
  # pointing at a gateway that 503s.
  #
  # Service names and ports were taken from `helm template` against the exact
  # pinned chart versions, not from the upstream docs.
  private_gw_route_candidates = {
    argocd = {
      enabled   = var.argocd.enabled
      namespace = "argocd"
      name      = "argocd-server"
      service   = "argocd-server"
      port      = 80
    }
    rollouts = {
      enabled   = var.argocd.rollouts.enabled && var.argocd.rollouts.dashboard.enabled
      namespace = "argocd"
      name      = "argo-rollouts-dashboard"
      service   = "argo-rollouts-dashboard"
      port      = 3100
    }
    goldilocks = {
      enabled   = var.goldilocks.enabled
      namespace = "monitoring-metrics"
      name      = "goldilocks-dashboard"
      service   = "goldilocks-dashboard"
      port      = 80
    }
    gatus = {
      enabled   = var.gatus.enabled
      namespace = "monitoring-other"
      name      = "gatus"
      service   = "gatus"
      port      = 80
    }
    kuma = {
      enabled   = var.uptime_kuma.enabled
      namespace = "monitoring-other"
      name      = "uptime-kuma"
      service   = "uptime-kuma"
      port      = 3001
    }
    grafana = {
      enabled   = var.prometheus.kube_stack.enabled && !var.cost_optimization.cost_analyzer
      namespace = "prometheus"
      name      = "kube-prometheus-stack-grafana"
      service   = "kube-prometheus-stack-grafana"
      port      = 80
    }
    prometheus = {
      enabled   = var.prometheus.kube_stack.enabled && !var.cost_optimization.cost_analyzer
      namespace = "prometheus"
      name      = "kube-prometheus-stack-prometheus"
      service   = "kube-prometheus-stack-prometheus"
      port      = 9090
    }
    alertmanager = {
      enabled   = var.prometheus.kube_stack.enabled && !var.cost_optimization.cost_analyzer && var.prometheus.kube_stack.alertmanager.enabled
      namespace = "prometheus"
      name      = "kube-prometheus-stack-alertmanager"
      service   = "kube-prometheus-stack-alertmanager"
      port      = 9093
    }
  }

  private_gw_routes = {
    for k, v in local.private_gw_route_candidates : k => v if v.enabled
  }
}

resource "kubernetes_manifest" "private_gw_routes" {
  for_each = var.envoy_gateway.enabled && var.envoy_gateway.private_gateway.enabled ? local.private_gw_routes : {}

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = each.value.name
      namespace = each.value.namespace
    }
    spec = {
      # Cross-namespace parentRef. No ReferenceGrant needed: the gateway's
      # HTTPS listener sets `allowedRoutes.namespaces.from = All`, and grants
      # are only required for cross-namespace *backendRefs*, which nothing here
      # uses — every route resolves a Service in its own namespace.
      parentRefs = [{
        name      = "private-gw-eg"
        namespace = "envoy-gateway-system"
      }]
      hostnames = ["${each.key}.${local.private_base_domain}"]
      rules = [{
        backendRefs = [{
          name = each.value.service
          port = each.value.port
        }]
      }]
    }
  }

  # A route created before its backing Service sits at `ResolvedRefs=False`
  # until the Service appears — recoverable, but it publishes a Route53 record
  # that 503s in the meantime. Ordering behind every release that can back a
  # row avoids that window. The list is wide because `for_each` cannot express
  # a per-key dependency; it costs nothing but graph edges.
  depends_on = [
    kubernetes_manifest.private_gateway_eg,
    helm_release.argocd,
    helm_release.argo_rollouts,
    helm_release.goldilocks,
    helm_release.gatus,
    helm_release.uptime_kuma,
    helm_release.kube_prometheus_stack,
  ]
}

# Folded in from the standalone `kubernetes_manifest.argocd_route_eg` that
# proved the pattern. Same object, same content — this is an address change
# only, so the plan must report no diff for it.
moved {
  from = kubernetes_manifest.argocd_route_eg[0]
  to   = kubernetes_manifest.private_gw_routes["argocd"]
}
