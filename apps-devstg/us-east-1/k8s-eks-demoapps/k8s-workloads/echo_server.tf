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
#------------------------------------------------------------------------------

locals {
  echo_server_namespace = "echo-server"
  echo_server_labels    = { app = "echo-server" }
}

resource "kubernetes_deployment" "echo_server" {
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
  metadata {
    name      = "echo-server"
    namespace = local.echo_server_namespace
    labels    = local.echo_server_labels
  }
  spec {
    selector = local.echo_server_labels
    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "echo_server" {
  metadata {
    name      = "echo-server"
    namespace = local.echo_server_namespace
    # Legacy annotation pattern used elsewhere in this repo (e.g. argo-cd):
    # ingress-nginx-private was launched with --ingress-class=private-apps,
    # so the controller filters by this annotation rather than the modern
    # spec.ingressClassName / IngressClass resource.
    # cert-manager auto-issues the per-host LE cert via DNS01 (public zone
    # fall-through, same trick the kgateway wildcard uses).
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
# kgateway smoke test: parallel HTTPRoute attaching to the platform-shared
# `private-gw` in `kgateway-system`. Distinct hostname (`echo-server-kg.…`)
# so externaldns-private creates a separate Route53 record and there's no
# overlap with the nginx Ingress path. TLS via the wildcard `*.aws.binbash.com.ar`
# cert bound to the gateway's HTTPS listener.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "echo_server_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "echo-server"
      namespace = "echo-server"
    }
    spec = {
      parentRefs = [{
        name      = "private-gw"
        namespace = "kgateway-system"
      }]
      hostnames = ["echo-server-kg.aws.binbash.com.ar"]
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
# Envoy Gateway smoke test: third parallel HTTPRoute attaching to the
# EG-managed `private-gw-eg` in `envoy-gateway-system`. Distinct hostname so
# externaldns-private creates a separate Route53 record. Same backend
# Service as the nginx + kgateway paths.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "echo_server_route_eg" {
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
