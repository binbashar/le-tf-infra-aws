#------------------------------------------------------------------------------
# DemoApp: echo-server (https://github.com/jmalloc/echo-server)
#
# Switched from Ealenn/Echo-Server (Helm chart 0.5.0, unmaintained since 2021,
# no WebSocket support) to jmalloc/echo-server (Go, HTTP at `/`, WebSocket
# echo at `/.ws`). The Ealenn chart had no extraEnv knob and never shipped WS.
#
# Deployed as native kubernetes_* resources rather than a chart — jmalloc
# publishes only an image, not a chart. The `echo-server` namespace was
# originally created by the Ealenn helm release with `create_namespace = true`
# and persisted through the helm uninstall (helm doesn't delete namespaces),
# so we leave it unmanaged here and reference it by string.
#
# Routing: exposed via the private nginx-ingress controller (internal NLB,
# reachable only over VPN). externaldns-private creates the Route53 record in
# the private zone (aws.binbash.com.ar). No public exposure.
#
# Two parallel hostnames hit the same backend Service, one per data plane:
#   - echo-server.aws.binbash.com.ar      → nginx-ingress (Ingress, below)
#   - echo-server-eg.aws.binbash.com.ar   → Envoy Gateway (HTTPRoute → private-gw-eg)
#
# Smoke-testing (VPN required for both):
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
}

resource "kubernetes_deployment" "echo_server" {
  count = var.demo_apps.echo_server.enabled ? 1 : 0

  metadata {
    name      = "echo-server"
    namespace = local.echo_server_namespace
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
    namespace = local.echo_server_namespace
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
    namespace = local.echo_server_namespace
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
# Envoy Gateway path: HTTPRoute attaching to the platform-shared
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
      namespace = "echo-server"
    }
    spec = {
      parentRefs = [{
        name      = "private-gw-eg"
        namespace = "envoy-gateway-system"
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
