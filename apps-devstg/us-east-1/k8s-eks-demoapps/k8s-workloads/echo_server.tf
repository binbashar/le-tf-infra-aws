#------------------------------------------------------------------------------
# DemoApp: echo-server (https://github.com/Ealenn/Echo-Server)
#
# Installed directly via Helm rather than as an ArgoCD Application — ArgoCD is
# not currently enabled in the k8s-components sublayer.
#
# Routing: this layer no longer owns its own Gateway. Traffic enters through
# the platform-shared `private-gw` Gateway in `kgateway-system` (provisioned
# in the k8s-components sublayer, fronted by an LBC-managed internal NLB).
# The HTTPRoute below attaches to it via cross-namespace parentRef and matches
# on the `echo-server.aws.binbash.com.ar` hostname.
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
      }
    })
  ]
}

#------------------------------------------------------------------------------
# HTTPRoute: bind to the shared private-gw and forward all traffic for the
# echo-server hostname to the chart's Service. Same-namespace backend, so no
# ReferenceGrant is needed.
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
