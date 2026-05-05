#------------------------------------------------------------------------------
# DemoApp: echo-server (https://github.com/Ealenn/Echo-Server)
#
# Installed directly via Helm rather than as an ArgoCD Application — ArgoCD is
# not currently enabled in the k8s-components sublayer.
#
# Routing: exposed via the private nginx-ingress controller (internal NLB,
# reachable only over VPN). externaldns-private creates the Route53 record in
# the private zone (aws.binbash.com.ar). No public exposure.
#------------------------------------------------------------------------------

resource "helm_release" "echo_server" {
  name       = "echo-server"
  repository = "https://ealenn.github.io/charts"
  chart      = "echo-server"
  version    = "0.5.0"

  namespace        = "echo-server"
  create_namespace = true

  values = [
    yamlencode({
      ingress = {
        enabled = true
        # Legacy annotation pattern used elsewhere in this repo (e.g. argo-cd):
        # ingress-nginx-private was launched with --ingress-class=private-apps,
        # so the controller filters by this annotation rather than the modern
        # spec.ingressClassName / IngressClass resource.
        # cert-manager auto-issues the per-host LE cert via DNS01 (public zone
        # fall-through, same trick the kgateway wildcard uses).
        annotations = {
          "kubernetes.io/ingress.class"   = "private-apps"
          "cert-manager.io/cluster-issuer" = "clusterissuer-binbash-cert-manager-clusterissuer"
        }
        hosts = [{
          host  = "echo-server.aws.binbash.com.ar"
          paths = ["/"]
        }]
        tls = [{
          hosts      = ["echo-server.aws.binbash.com.ar"]
          secretName = "echo-server-tls"
        }]
      }
    })
  ]
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
