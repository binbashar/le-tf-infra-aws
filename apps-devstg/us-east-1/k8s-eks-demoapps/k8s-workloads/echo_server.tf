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
# Routing: three hostnames hit the same backend Service.
#
#   - echo-server.aws.binbash.com.ar     → nginx-ingress (Ingress, below)
#                                          Internal NLB, VPN only.
#   - echo-server-eg.aws.binbash.com.ar  → Envoy Gateway, private-gw-eg
#                                          Internal NLB, VPN only. Keeps the
#                                          `-eg` suffix because nginx already
#                                          owns the unsuffixed private name.
#   - echo-server.binbash.com.ar         → Envoy Gateway, public-gw-eg
#                                          Internet-facing NLB, reachable only
#                                          from the CIDRs allowlisted in
#                                          k8s-components' `envoy_gateway.
#                                          public_gateway.allowed_cidrs`. No
#                                          `-eg` suffix needed: nothing else
#                                          publishes into the public zone, so
#                                          this follows the plain
#                                          <app>.binbash.com.ar convention.
#
# All three are HTTPS. The nginx path gets a per-host cert from cert-manager;
# both Envoy Gateway paths inherit the wildcard bound to their gateway's HTTPS
# listener (*.aws.binbash.com.ar and *.binbash.com.ar respectively).
#
# externaldns-private publishes the two `aws.` records into the private zone;
# externaldns-public publishes the public one into binbash.com.ar.
#
# Smoke-testing (VPN required for the two private hosts; the public one
# requires being on an allowlisted source IP):
#
#   curl https://echo-server.binbash.com.ar/
#
#   # HTTP (returns the request as plain text, jmalloc-style):
#   curl https://echo-server-eg.aws.binbash.com.ar/
#
#   # WebSocket — `wscat` is the simplest interactive client. It defaults to
#   # HTTP/1.1, which matters for the nginx host: nginx-ingress negotiates
#   # HTTP/2 via ALPN and `websocat 1.x` cannot do WS-over-HTTP/2 (RFC 8441),
#   # so it errors with "I/O failure" against echo-server.aws…; wscat works
#   # against both hosts.
#   #   brew install wscat   (or: npm i -g wscat)
#   wscat -c wss://echo-server.aws.binbash.com.ar/.ws       # nginx
#   wscat -c wss://echo-server-eg.aws.binbash.com.ar/.ws    # envoy-gateway
#   # Type any line at the `>` prompt; jmalloc echoes it back prefixed with
#   # a `Request served by …` line on first frame.
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

  # Gateways provisioned by the k8s-components layer. Referenced by name (that
  # layer exports no outputs); keep in sync with networking-envoygateway.tf.
  envoy_gateway_namespace = "envoy-gateway-system"
  private_gateway_name    = "private-gw-eg"
  public_gateway_name     = "public-gw-eg"

  # `public-gw-eg`'s HTTPS listener only accepts HTTPRoutes from namespaces
  # carrying this label — see `local.public_gw_eg_exposure_label` in
  # k8s-components/locals.tf. Without it the HTTPRoute below is created but
  # never attaches, and the app stays unreachable from the internet.
  public_exposure_label = { "gateway.binbash.com.ar/public-exposure" = "allowed" }
}

resource "kubernetes_namespace" "echo_server" {
  count = var.demo_apps.echo_server.enabled ? 1 : 0

  metadata {
    name   = local.echo_server_namespace
    labels = var.demo_apps.echo_server.public_endpoint ? local.public_exposure_label : {}
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

resource "kubernetes_ingress_v1" "echo_server" {
  count = var.demo_apps.echo_server.enabled ? 1 : 0

  metadata {
    name      = "echo-server"
    namespace = kubernetes_namespace.echo_server[0].metadata[0].name
    # Legacy annotation pattern used elsewhere in this repo (e.g. argo-cd):
    # ingress-nginx-private was launched with --ingress-class=private-apps,
    # so the controller filters by this annotation rather than the modern
    # spec.ingressClassName / IngressClass resource.
    # cert-manager auto-issues the per-host LE cert via DNS01 (public zone
    # fall-through, same trick the Envoy Gateway wildcard uses).
    annotations = {
      "kubernetes.io/ingress.class"    = "private-apps"
      "cert-manager.io/cluster-issuer" = "clusterissuer-binbash-cert-manager-clusterissuer"
    }
  }
  spec {
    tls {
      hosts       = ["echo-server.aws.binbash.com.ar"]
      secret_name = "echo-server-tls"
    }
    rule {
      host = "echo-server.aws.binbash.com.ar"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "echo-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

#------------------------------------------------------------------------------
# Envoy Gateway, private path: HTTPRoute attaching to the platform-shared
# `private-gw-eg` in `envoy-gateway-system` via cross-namespace parentRef.
# Distinct hostname from the nginx Ingress so externaldns-private creates a
# separate Route53 record and the two paths don't overlap. Same backend
# Service as the nginx path. TLS comes from the wildcard
# `*.aws.binbash.com.ar` cert bound to the gateway's HTTPS listener.
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
      parentRefs = [{
        name      = local.private_gateway_name
        namespace = local.envoy_gateway_namespace
      }]
      hostnames = ["echo-server-eg.aws.binbash.com.ar"]
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
#   1. The namespace label applied above — without it the HTTPS listener
#      refuses the attachment and this route resolves to nothing.
#   2. The NLB security group, which only admits
#      `envoy_gateway.public_gateway.allowed_cidrs`.
#
# There is no HTTP variant: the public gateway's port-80 listener only accepts
# routes from its own namespace, and the redirector living there sends
# everything to HTTPS.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "echo_server_route_eg_public" {
  count = var.demo_apps.echo_server.enabled && var.demo_apps.echo_server.public_endpoint ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "echo-server-eg-public"
      namespace = kubernetes_namespace.echo_server[0].metadata[0].name
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
  from = kubernetes_ingress_v1.echo_server
  to   = kubernetes_ingress_v1.echo_server[0]
}
moved {
  from = kubernetes_manifest.echo_server_route
  to   = kubernetes_manifest.echo_server_route[0]
}
moved {
  from = kubernetes_manifest.echo_server_route_eg
  to   = kubernetes_manifest.echo_server_route_eg[0]
}
