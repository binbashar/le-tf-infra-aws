#------------------------------------------------------------------------------
# DemoApp: echo-server (https://github.com/jmalloc/echo-server)
#
# Switched from Ealenn/Echo-Server (Helm chart 0.5.0, unmaintained since 2021,
# no WebSocket support) to jmalloc/echo-server (Go, HTTP at `/`, WebSocket
# echo at `/.ws`). The Ealenn chart had no extraEnv knob and never shipped WS.
#
# Deployed as native kubernetes_* resources rather than a chart — jmalloc
# publishes only an image, not a chart. The `echo-server` namespace used to be
# left unmanaged here: it had been created by the old Ealenn helm release with
# `create_namespace = true` and survived the uninstall, so referencing it by
# string happened to work. That assumption dies with the cluster — on a
# rebuilt cluster the namespace simply isn't there and every resource below
# fails to apply. It's managed here now so the layer stands up from scratch.
#
# Routing: two hostnames hit the same backend Service, both on Envoy Gateway.
#
#   - echo-server.aws.binbash.com.ar     → Envoy Gateway, private-gw-eg
#                                          Internal NLB, VPN only.
#   - echo-server.binbash.com.ar         → Envoy Gateway, public-gw-eg
#                                          Internet-facing ALB, open at the
#                                          perimeter. This hostname is closed
#                                          by its own SecurityPolicy, from
#                                          `echo_server_public_allowed_cidrs`
#                                          in this layer.
#
# Both follow the plain <app>.<zone> convention. There used to be a third,
# `echo-server-eg.aws.binbash.com.ar`, carrying an `-eg` suffix purely because
# nginx-ingress owned the unsuffixed private name; the nginx → Envoy migration
# moved that name here and the suffixed one was retired with it.
#
# Both are HTTPS and inherit the wildcard bound to their gateway's HTTPS
# listener (*.aws.binbash.com.ar and *.binbash.com.ar respectively) — no
# per-host cert-manager Certificate is involved any more.
#
# externaldns-private publishes the `aws.` record into the private zone;
# externaldns-public publishes the public one into binbash.com.ar.
#
# Smoke-testing (VPN required for the private host; the public one requires
# being on an allowlisted source IP):
#
#   # HTTP (returns the request as plain text, jmalloc-style):
#   curl https://echo-server.aws.binbash.com.ar/
#   curl https://echo-server.binbash.com.ar/
#
#   # WebSocket — `wscat` is the simplest interactive client.
#   #   brew install wscat   (or: npm i -g wscat)
#   wscat -c wss://echo-server.aws.binbash.com.ar/.ws
#   # Type any line at the `>` prompt; jmalloc echoes it back prefixed with
#   # a `Request served by …` line on first frame.
#   # (The old HTTP/2-vs-`websocat 1.x` caveat here applied to nginx's ALPN
#   # negotiation and died with the nginx path.)
#
#   # Raw upgrade handshake check via curl (forces HTTP/1.1 so it works
#   # everywhere, prints the `101 Switching Protocols` response):
#   curl -k --http1.1 -i \
#     -H "Connection: Upgrade" -H "Upgrade: websocket" \
#     -H "Sec-WebSocket-Key: $(openssl rand -base64 16)" \
#     -H "Sec-WebSocket-Version: 13" \
#     https://echo-server.aws.binbash.com.ar/.ws
#
# The Service port carries `appProtocol = "kubernetes.io/ws"` (see
# kubernetes_service.echo_server below) — the portable Gateway API signal that
# the backend accepts WS upgrades. Neither nginx nor Envoy Gateway needs it,
# but it costs nothing and keeps the backend implementation-agnostic.
#------------------------------------------------------------------------------

locals {
  echo_server_namespace = "echo-server"
  echo_server_labels    = { app = "echo-server" }

  # The gateways this file attaches to, the label the public one demands and the
  # conventions both routes follow now live in `locals.tf` — they describe the
  # platform, and three workloads read them.

  # Opts this namespace into Goldilocks (k8s-components/scaling.tf). Goldilocks
  # only creates VPA objects for namespaces carrying this label, so without it
  # its dashboard renders an empty table — which is why echo-server, the one
  # real workload on this cluster, is the namespace that gets it.
  #
  # This observes; it does not mutate. VPA runs recommendation-only
  # (`admissionController: false` in chart-values/vpa.yaml), so the label
  # produces resource *recommendations* for the echo-server Deployment and
  # never rewrites its requests or limits. Inert when Goldilocks is not
  # installed — nothing else reads the label.
  #
  # Applied unconditionally rather than behind a variable: this layer has no
  # visibility into whether k8s-components enabled Goldilocks, and a label no
  # controller reads costs nothing.
  goldilocks_label = { "goldilocks.fairwinds.com/enabled" = "true" }
}

resource "kubernetes_namespace" "echo_server" {
  count = var.demo_apps.echo_server.enabled ? 1 : 0

  metadata {
    name = local.echo_server_namespace
    labels = merge(
      local.goldilocks_label,
      var.demo_apps.echo_server.public_endpoint ? local.public_exposure_label : {},
    )
  }
}

resource "kubernetes_deployment" "echo_server" {
  count = var.demo_apps.echo_server.enabled ? 1 : 0

  metadata {
    name      = "echo-server"
    namespace = kubernetes_namespace.echo_server[0].metadata[0].name
    labels    = local.echo_server_labels
  }

  spec {
    replicas = 1
    selector {
      match_labels = local.echo_server_labels
    }
    template {
      metadata {
        labels = local.echo_server_labels
      }
      spec {
        container {
          name  = "echo-server"
          image = "jmalloc/echo-server:v0.3.7"
          port {
            container_port = 8080
            name           = "http"
          }
          resources {
            limits = {
              cpu    = "50m"
              memory = "64Mi"
            }
            requests = {
              cpu    = "10m"
              memory = "32Mi"
            }
          }

          # This backend is reachable from the internet, so the two pieces of
          # hygiene that matter for it are here rather than left to the demo's
          # informality.
          #
          # The probe hits `/` because echo-server answers 200 on every path;
          # there is no dedicated health endpoint to prefer. What it buys is
          # that the Service stops sending traffic to a pod whose process died
          # but whose container has not been restarted yet -- the window where
          # the gateway returns 503s that look like a routing fault.
          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 2
            period_seconds        = 10
            timeout_seconds       = 2
          }

          # `jmalloc/echo-server` is a static Go binary that serves HTTP on
          # 8080 and writes nothing, so it needs none of what this drops: no
          # root, no writable filesystem, no capabilities, no privilege
          # escalation. 8080 is above 1024, so an unprivileged UID can bind it.
          security_context {
            run_as_non_root            = true
            run_as_user                = 65534
            allow_privilege_escalation = false
            read_only_root_filesystem  = true

            capabilities {
              drop = ["ALL"]
            }

            seccomp_profile {
              type = "RuntimeDefault"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "echo_server" {
  count = var.demo_apps.echo_server.enabled ? 1 : 0

  metadata {
    name      = "echo-server"
    namespace = kubernetes_namespace.echo_server[0].metadata[0].name
    labels    = local.echo_server_labels
  }
  spec {
    selector = local.echo_server_labels
    # Gateway API v1.2+ standard signal that this backend accepts WebSocket
    # upgrades (KEP-3726). Envoy Gateway allows WS by default and nginx
    # ignores the field, so neither current path needs it — kept because it's
    # the portable way to declare WS support and some implementations (e.g.
    # kgateway, which this layer previously ran) reject `/.ws` upgrades
    # without it. See the WebSocket notes in the file header.
    port {
      name         = "http"
      port         = 80
      target_port  = 8080
      protocol     = "TCP"
      app_protocol = "kubernetes.io/ws"
    }
  }
}

#------------------------------------------------------------------------------
# The nginx Ingress that used to own `echo-server.aws.binbash.com.ar` was
# removed here — the hostname now lives on the `echo-server-eg` HTTPRoute above
# and is served by the Envoy private gateway. It was deleted rather than
# emptied because that host was its only rule, so stripping it would have left
# an Ingress with nothing in it.
#
# Two things went with it: the per-host cert-manager Certificate/Secret
# (`echo-server-tls`, triggered by the `cert-manager.io/cluster-issuer`
# annotation), now superseded by the `*.aws.binbash.com.ar` wildcard bound to
# the gateway's HTTPS listener; and the last live consumer of the
# `private-apps` ingress class.
#
# Rolling back means re-adding this resource and waiting out a fresh DNS01
# issuance (~4 min). During the cutover itself the `-eg` hostname served as the
# instant rollback; it has since been retired, so that shortcut is gone.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Envoy Gateway, private path: HTTPRoute attaching to the platform-shared
# `private-gw-eg` in `envoy-gateway-system` via cross-namespace parentRef.
# Owns `echo-server.aws.binbash.com.ar` outright since the nginx migration.
# TLS comes from the wildcard `*.aws.binbash.com.ar` cert bound to the
# gateway's HTTPS listener.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "echo_server_route_eg" {
  count = var.demo_apps.echo_server.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "echo-server-eg"
      namespace = kubernetes_namespace.echo_server[0].metadata[0].name
    }
    spec = {
      parentRefs = local.private_gw_parent_refs
      # The `-eg` suffix is gone. It only ever existed because nginx owned the
      # unsuffixed private name; once the cutover moved that name here, the
      # suffixed one was redundant and was dropped. external-dns runs policy
      # `sync`, so removing it from this list is enough — the Route53 record is
      # deleted on the next reconcile, no manual cleanup.
      hostnames = ["echo-server.aws.binbash.com.ar"]
      rules = [{
        backendRefs = [{
          name = "echo-server"
          port = 80
        }]
      }]
    }
  }
}

#------------------------------------------------------------------------------
# Envoy Gateway, public path: same backend Service, exposed on
# `echo-server.binbash.com.ar` through `public-gw-eg`. TLS is the
# `*.binbash.com.ar` wildcard bound to that gateway's HTTPS listener, and
# externaldns-public creates the record in the public zone.
#
# Reachability is gated in two independent places, both in k8s-components:
#   1. The namespace label applied above — without it the listener refuses the
#      attachment and this route resolves to nothing.
#   2. The allowlist on whichever load balancer fronts the gateway.
#
# No `sectionName`: the route attaches to every listener whose hostname is
# compatible. Which one actually carries traffic depends on
# `envoy_gateway.public_gateway.frontend` — the HTTPS listener under `nlb`, the
# HTTP one under `alb`, where the ALB has already terminated TLS.
#
# `external-dns/controller: none` because under the ALB frontend the record is
# published from that ALB's Ingress. Without it both objects claim the same
# hostname under one `txtOwnerId` and external-dns picks a winner by its own
# dedup order. Harmless under `nlb`, where the Ingress does not exist — but
# leaving it unconditional keeps the two frontends from differing here.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "echo_server_route_eg_public" {
  count = var.demo_apps.echo_server.enabled && var.demo_apps.echo_server.public_endpoint ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "echo-server-eg-public"
      namespace = kubernetes_namespace.echo_server[0].metadata[0].name
      annotations = {
        "external-dns.alpha.kubernetes.io/controller" = "none"
      }
    }
    spec = {
      parentRefs = [{
        name      = local.public_gateway_name
        namespace = local.envoy_gateway_namespace
      }]
      hostnames = ["echo-server.binbash.com.ar"]
      rules = [{
        backendRefs = [{
          name = "echo-server"
          port = 80
        }]
      }]
    }
  }
}

#------------------------------------------------------------------------------
# Per-application source-IP filtering for the public hostname.
#
# This is the Gateway API translation of nginx-ingress's
# `whitelist-source-range` annotation: the restriction is declared by the
# application, next to its own route, rather than centrally at the perimeter.
# An app with no policy is reachable by anyone the load balancer admits, which
# is what an Ingress without the annotation does.
#
# Enforced at L7 by Envoy, which means it depends on Envoy having the real
# client address. Behind the ALB that comes from the `ClientTrafficPolicy` in
# k8s-components (`numTrustedHops`) -- without it every request would appear to
# come from the load balancer and this policy would match all of them or none.
# Behind an NLB the address is preserved at L4 and no policy is needed.
#
# `defaultAction = Deny` rather than relying on the absence of a match: an
# authorization rule set that only lists allows, with a permissive default,
# fails open on a typo.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "echo_server_public_ip_allowlist" {
  count = var.demo_apps.echo_server.enabled && var.demo_apps.echo_server.public_endpoint && var.demo_apps.echo_server.restrict_public_access ? 1 : 0

  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "SecurityPolicy"
    metadata = {
      name      = "echo-server-public-ip-allowlist"
      namespace = kubernetes_namespace.echo_server[0].metadata[0].name
    }
    spec = {
      targetRefs = [{
        group = "gateway.networking.k8s.io"
        kind  = "HTTPRoute"
        name  = kubernetes_manifest.echo_server_route_eg_public[0].manifest.metadata.name
      }]
      authorization = {
        defaultAction = "Deny"
        rules = [{
          action = "Allow"
          principal = {
            clientCIDRs = var.echo_server_public_allowed_cidrs
          }
        }]
      }
    }
  }

  lifecycle {
    precondition {
      condition     = length(var.echo_server_public_allowed_cidrs) > 0
      error_message = "echo_server_public_allowed_cidrs must not be empty while echo_server.restrict_public_access is true: the SecurityPolicy would deny every request, including your own. Set it in allowlist.local.auto.tfvars (see allowlist.local.auto.tfvars.example), or set restrict_public_access = false to publish the hostname openly."
    }
  }

  depends_on = [
    kubernetes_manifest.echo_server_route_eg_public,
  ]
}

#------------------------------------------------------------------------------
# State address shifts when `count` was introduced on the resources above.
# These let `tofu apply` reconcile the existing live objects from
# `kubernetes_*.echo_server` to `kubernetes_*.echo_server[0]` without a
# destroy/create cycle. Safe to keep — they're no-ops once state has caught up.
#------------------------------------------------------------------------------
moved {
  from = kubernetes_deployment.echo_server
  to   = kubernetes_deployment.echo_server[0]
}
moved {
  from = kubernetes_service.echo_server
  to   = kubernetes_service.echo_server[0]
}
moved {
  from = kubernetes_manifest.echo_server_route
  to   = kubernetes_manifest.echo_server_route[0]
}
moved {
  from = kubernetes_manifest.echo_server_route_eg
  to   = kubernetes_manifest.echo_server_route_eg[0]
}
