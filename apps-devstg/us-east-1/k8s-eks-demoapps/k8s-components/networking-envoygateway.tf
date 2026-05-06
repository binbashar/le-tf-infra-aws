#------------------------------------------------------------------------------
# Envoy Gateway (CNCF, Envoy maintainers' official Gateway API implementation)
# -----------------------------------------------------------------------------
# Third parallel data plane in this layer alongside nginx-ingress and
# kgateway. Same Gateway API CRDs (already installed by the kgateway file's
# `kubernetes_manifest.gateway_api_crds`) — EG is partitioned from kgateway
# via a separate GatewayClass (`envoy-gateway` here vs `kgateway`) and a
# distinct controller string. No webhook conflicts; the two control planes
# only reconcile Gateways whose `gatewayClassName` resolves to a
# GatewayClass with their own controller name.
#
# Install order (enforced via depends_on):
#   1. Upstream Gateway API CRDs (provided by networking-kgateway.tf)
#   2. EG CRDs (gateway.envoyproxy.io group only — gateway API toggled off
#      so we don't clobber the standard-channel CRDs already in cluster)
#   3. EG controller (with --skip-crds equivalent to avoid the same clobber)
#
# Docs: https://gateway.envoyproxy.io/docs/
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# 1. EG CRDs (gateway.envoyproxy.io group only)
# We deliberately bypass the `gateway-crds-helm` subchart: its chart archive
# (Gateway API standard + experimental + EG) bloats the helm release Secret
# beyond etcd's 1 MB-per-object limit. Pulling the rendered CRDs YAML from
# the EG release page and applying via kubernetes_manifest sidesteps this —
# same pattern as the Gateway API CRDs in networking-kgateway.tf.
#------------------------------------------------------------------------------
data "http" "envoy_gateway_crds" {
  count = var.envoy_gateway.enabled ? 1 : 0
  url   = "https://github.com/envoyproxy/gateway/releases/download/${var.envoy_gateway.version}/envoy-gateway-crds.yaml"
}

locals {
  _envoy_gateway_crds_body = try(data.http.envoy_gateway_crds[0].response_body, "")
  envoy_gateway_crd_manifests = {
    for doc in [
      for chunk in split("\n---\n", local._envoy_gateway_crds_body) :
      try(yamldecode(chunk), null)
      ] : doc.metadata.name => {
      for k, v in doc : k => v if k != "status"
    } if doc != null && try(doc.kind, "") != ""
  }
}

resource "kubernetes_manifest" "envoy_gateway_crds" {
  for_each = local.envoy_gateway_crd_manifests
  manifest = each.value
}

#------------------------------------------------------------------------------
# 2. EG controller. skip_crds=true because the gateway-helm chart bundles
# both Gateway API and EG CRDs under `crds/` (helm auto-installs them on
# first release). Both groups are managed elsewhere in this layer.
#------------------------------------------------------------------------------
resource "helm_release" "envoy_gateway" {
  count            = var.envoy_gateway.enabled ? 1 : 0
  name             = "envoy-gateway"
  namespace        = kubernetes_namespace.envoy_gateway[0].id
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = var.envoy_gateway.version
  create_namespace = false
  skip_crds        = true

  values = [
    templatefile("chart-values/envoy-gateway.yaml", {
      nodeSelector = local.tools_nodeSelector
      tolerations  = local.tools_tolerations
    })
  ]

  depends_on = [
    kubernetes_manifest.envoy_gateway_crds,
  ]
}

#------------------------------------------------------------------------------
# Shared private Gateway (`private-gw-eg`)
# -----------------------------------------------------------------------------
# Mirror of kgateway's `private-gw`. Distinct GatewayClass (`envoy-gateway`)
# means EG reconciles this Gateway, kgateway does not. Same NLB pattern: an
# AWS LBC-managed internal NLB fronts the EG-provisioned Envoy Service.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# EnvoyProxy: parameters consumed by the GatewayClass below. Carries node
# scheduling for the EG-provisioned Envoy data-plane Deployment + the three
# AWS LBC annotations that turn the auto-created Service into an internal
# NLB targeting pod IPs directly.
#
# IMPORTANT: EG references EnvoyProxy at the GatewayClass level (via
# `spec.parametersRef`), not at the Gateway level (where kgateway puts its
# GatewayParameters). All Gateways using class `envoy-gateway` share these
# params — fine for one Gateway today; if per-Gateway tuning ever needed,
# create another GatewayClass with a different EnvoyProxy.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "private_gw_eg_proxy" {
  count = var.envoy_gateway.enabled && var.envoy_gateway.private_gateway.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = "private-gw-eg-proxy"
      namespace = kubernetes_namespace.envoy_gateway[0].id
    }
    spec = {
      provider = {
        type = "Kubernetes"
        kubernetes = {
          envoyDeployment = {
            pod = {
              nodeSelector = { stack = "tools" }
              tolerations = [{
                key      = "stack"
                operator = "Equal"
                value    = "tools"
                effect   = "NoSchedule"
              }]
            }
          }
          envoyService = {
            annotations = {
              "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
              "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
              "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internal"
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.envoy_gateway,
  ]
}

#------------------------------------------------------------------------------
# GatewayClass: cluster-scoped, named `envoy-gateway` (parallel to the
# kgateway-installed `kgateway` class). Pinned to EG's controller string;
# parametersRef points at the EnvoyProxy above.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "envoy_gateway_class" {
  count = var.envoy_gateway.enabled && var.envoy_gateway.private_gateway.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "envoy-gateway"
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = kubernetes_manifest.private_gw_eg_proxy[0].manifest.metadata.name
        namespace = kubernetes_namespace.envoy_gateway[0].id
      }
    }
  }

  depends_on = [
    kubernetes_manifest.private_gw_eg_proxy,
  ]
}

#------------------------------------------------------------------------------
# The Gateway itself.
# - `http` listener: namespaces.from = "Same" so only platform routes (i.e.
#   the redirect HTTPRoute below) attach. App HTTPRoutes can't see this
#   listener, so they're HTTPS-only by construction.
# - `https` listener: namespaces.from = "All" + TLS Terminate against the
#   EG-namespace wildcard secret.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "private_gateway_eg" {
  count = var.envoy_gateway.enabled && var.envoy_gateway.private_gateway.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "private-gw-eg"
      namespace = kubernetes_namespace.envoy_gateway[0].id
    }
    spec = {
      gatewayClassName = "envoy-gateway"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
          allowedRoutes = {
            namespaces = { from = "Same" }
          }
        },
        {
          name     = "https"
          protocol = "HTTPS"
          port     = 443
          allowedRoutes = {
            namespaces = { from = "All" }
          }
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              name = local.private_gw_eg_wildcard_cert_secret
            }]
          }
        },
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.envoy_gateway_class,
    helm_release.alb_ingress,
    helm_release.private_gw_eg_tls,
  ]
}

#------------------------------------------------------------------------------
# Platform-shared HTTP→HTTPS redirector (mirror of kgateway's). Pinned to
# the http listener via sectionName; matches all paths; 301 (Gateway API
# rejects 308).
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "private_gateway_eg_https_redirect" {
  count = var.envoy_gateway.enabled && var.envoy_gateway.private_gateway.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "private-gw-eg-https-redirect"
      namespace = kubernetes_namespace.envoy_gateway[0].id
    }
    spec = {
      parentRefs = [{
        name        = kubernetes_manifest.private_gateway_eg[0].manifest.metadata.name
        sectionName = "http"
      }]
      rules = [{
        matches = [{
          path = {
            type  = "PathPrefix"
            value = "/"
          }
        }]
        filters = [{
          type = "RequestRedirect"
          requestRedirect = {
            scheme     = "https"
            statusCode = 301
          }
        }]
      }]
    }
  }

  depends_on = [
    kubernetes_manifest.private_gateway_eg,
  ]
}

#------------------------------------------------------------------------------
# TLS for `private-gw-eg`: separate wildcard `*.aws.binbash.com.ar` Certificate
# in the EG namespace, sharing the cluster-scoped ClusterIssuer with kgateway
# (see `helm_release.cluster_issuer_binbash_aws` in networking-cluster-issuer.tf).
# Same DNS01 / public-zone fall-through trick as kgateway.
#------------------------------------------------------------------------------
resource "helm_release" "private_gw_eg_tls" {
  count = var.envoy_gateway.enabled && var.envoy_gateway.private_gateway.enabled && var.certmanager.enabled ? 1 : 0

  name       = "private-gw-eg-tls"
  namespace  = kubernetes_namespace.envoy_gateway[0].id
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "raw"
  version    = "0.1.0"

  values = [
    <<-EOF
    resources:
      - apiVersion: cert-manager.io/v1
        kind: Certificate
        metadata:
          name: private-gw-eg-wildcard
          namespace: ${kubernetes_namespace.envoy_gateway[0].id}
        spec:
          secretName: ${local.private_gw_eg_wildcard_cert_secret}
          issuerRef:
            kind: ClusterIssuer
            name: ${local.shared_clusterissuer_name}
          commonName: ${local.private_base_domain}
          dnsNames:
            - ${local.private_base_domain}
            - "*.${local.private_base_domain}"
    EOF
  ]

  depends_on = [
    helm_release.cluster_issuer_binbash_aws,
  ]
}
