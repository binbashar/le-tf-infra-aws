#------------------------------------------------------------------------------
# Envoy Gateway — the L7 data plane for this cluster
# -----------------------------------------------------------------------------
# ** Read README.md in this directory first. ** It covers the topology, how to
# expose an app, the decisions that surprise people, and the operational
# gotchas. This file keeps only the reasoning that belongs to specific lines.
#
# Install order, enforced by depends_on:
#   1. Upstream Gateway API CRDs (networking-gateway-api.tf)
#   2. EG CRDs, `gateway.envoyproxy.io` group only
#   3. EG controller
#
# Steps 2 and 3 both avoid shipping the standard-channel Gateway API CRDs so
# they cannot clobber the ones step 1 owns.
#
# Docs: https://gateway.envoyproxy.io/docs/
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# 1. EG CRDs (gateway.envoyproxy.io group only)
# We deliberately bypass the `gateway-crds-helm` subchart: its chart archive
# (Gateway API standard + experimental + EG) bloats the helm release Secret
# beyond etcd's 1 MB-per-object limit. Applying the rendered CRDs YAML via
# kubernetes_manifest sidesteps this — same pattern as the Gateway API CRDs in
# networking-gateway-api.tf.
#
# Vendored under crds/ for the reasons documented in networking-gateway-api.tf,
# with the version in the filename so a bump of `version` below that forgets to
# re-vendor fails on a missing file rather than pairing new chart with old CRDs.
#------------------------------------------------------------------------------
locals {
  envoy_gateway_crds_path = "${path.module}/crds/envoy-gateway-crds-${var.envoy_gateway.version}.yaml"

  # Guarded on the flag — see networking-gateway-api.tf.
  _envoy_gateway_crds_body = var.envoy_gateway.enabled ? file(local.envoy_gateway_crds_path) : ""
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

#==============================================================================
# Private Gateway (`private-gw-eg`) — VPN-only, internal NLB
#==============================================================================

#------------------------------------------------------------------------------
# EnvoyProxy: node scheduling for the EG-provisioned data plane, plus the LBC
# annotations that shape the Service it creates. Consumed by the GatewayClass
# below — EG reads EnvoyProxy at the *GatewayClass* level, which is why the
# public gateway needs a class of its own rather than reusing this one.
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
          # target-type `instance` (NLB -> NodePort -> pod), not `ip`, to
          # preserve the client IP. On `ip` target groups AWS defaults
          # `preserve_client_ip.enabled` to false for TCP, so Envoy sees the
          # NLB as the peer and writes *that* into `X-Forwarded-For`. On
          # `instance` the source IP is preserved and cannot be disabled — the
          # target-type alone is the whole fix, there is no companion attribute.
          #
          # Depends on `externalTrafficPolicy: Local`, or kube-proxy SNATs the
          # source away again. EG already defaults the provisioned Service to
          # `Local` — nothing to set, but do not assume it across EG upgrades.
          #
          # This was expected to cost a small latency tail. It does not: S6 in
          # loadtest/test-results.md put both data planes on identical
          # `instance` plumbing and the tail turned out to be nginx's, not the
          # target-type's.
          envoyService = {
            annotations = {
              "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
              "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
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
# GatewayClass, cluster-scoped. Pinned to EG's controller string so only EG
# reconciles Gateways naming it.
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
# The Gateway. `http` accepts routes only from this namespace, so the redirect
# below is the only thing on port 80 and app routes are HTTPS-only by
# construction. `https` accepts from anywhere — reaching this NLB already
# requires VPN.
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
    # Provisions a Service of type LoadBalancer via the Envoy Gateway
    # controller. The drain gate keeps both controllers alive long enough to
    # garbage collect it on destroy -- see networking-ingress.tf.
    time_sleep.controller_drain,
  ]
}

#------------------------------------------------------------------------------
# HTTP→HTTPS redirector, pinned to the http listener via sectionName. 301
# because Gateway API rejects nginx's default 308.
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
# TLS for `private-gw-eg`: the `*.aws.binbash.com.ar` wildcard bound to the
# HTTPS listener above.
#
# Worth knowing: DNS01 works even though `aws.binbash.com.ar` is a private-only
# zone. It has no public NS delegation, so public lookups for
# `_acme-challenge.<host>` fall up the chain to the `binbash.com.ar` NS
# servers; cert-manager writes the TXT into the public zone (where its IRSA
# role has permissions) and Let's Encrypt reads it from there.
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

#==============================================================================
# Public Gateway (`public-gw-eg`) — internet-facing NLB, CIDR-allowlisted
#==============================================================================
# Same shape as the private one. It differs in three ways, all covered in
# README.md: an `internet-facing` NLB in the public subnets, a CIDR allowlist
# on that NLB's security group, and an HTTPS listener that only accepts routes
# from namespaces carrying an opt-in label.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# EnvoyProxy for the public data plane.
#
# On `load-balancer-source-ranges`: with no
# `aws-load-balancer-security-groups` annotation the LBC creates and manages a
# frontend SG for the NLB and renders this list into its ingress rules. Omit
# the annotation and the LBC defaults that group to 0.0.0.0/0 — hence the
# precondition below, which fails the plan instead of silently publishing an
# open endpoint. It is a precondition rather than a variable validation so it
# only fires when the public gateway is actually being provisioned.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "public_gw_eg_proxy" {
  count = var.envoy_gateway.enabled && var.envoy_gateway.public_gateway.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = "public-gw-eg-proxy"
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
          # target-type `instance`, matching the private gateway — see the note
          # there for the mechanics.
          #
          # This was held back on `ip` at first, on the theory that preserving
          # the client IP would break the CIDR allowlist. It does not, for two
          # independent reasons: the allowlist lives on the NLB's own frontend
          # SG and is evaluated before the LB forwards anything, and the
          # node-side rule the LBC writes is a security-group *reference* to
          # the shared backend group, which AWS documents as working "even if
          # you enable client IP preservation". So it needs no duplication onto
          # the node SG.
          #
          # Side effect worth knowing: Envoy now sees the real client address,
          # so an L7 CIDR match (SecurityPolicy `principal.clientCIDRs`) is
          # viable without proxy protocol v2. Unused — the SG is cheaper and
          # drops traffic earlier — but it is an option if WAF gets revisited.
          envoyService = {
            annotations = {
              "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
              "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
              "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
              "service.beta.kubernetes.io/load-balancer-source-ranges"       = join(",", var.envoy_gateway_public_allowed_cidrs)
            }
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = length(var.envoy_gateway_public_allowed_cidrs) > 0
      error_message = "envoy_gateway_public_allowed_cidrs must not be empty while the public gateway is enabled: the AWS Load Balancer Controller would default the NLB's security group to 0.0.0.0/0 and expose the endpoint to the entire internet. Set it in allowlist.local.auto.tfvars (see allowlist.local.auto.tfvars.example)."
    }
  }

  depends_on = [
    helm_release.envoy_gateway,
  ]
}

#------------------------------------------------------------------------------
# GatewayClass for the public data plane. Same controller string as the
# private one — EG reconciles both — but a distinct name so it can point at
# its own EnvoyProxy.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "envoy_gateway_class_public" {
  count = var.envoy_gateway.enabled && var.envoy_gateway.public_gateway.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "envoy-gateway-public"
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = kubernetes_manifest.public_gw_eg_proxy[0].manifest.metadata.name
        namespace = kubernetes_namespace.envoy_gateway[0].id
      }
    }
  }

  depends_on = [
    kubernetes_manifest.public_gw_eg_proxy,
  ]
}

#------------------------------------------------------------------------------
# The public Gateway. `http` behaves like the private one. `https` uses a label
# Selector rather than `All`: this is the opt-in gate for internet exposure, so
# writing an HTTPRoute is not by itself enough to publish a workload — a
# cluster admin has to label the namespace first.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "public_gateway_eg" {
  count = var.envoy_gateway.enabled && var.envoy_gateway.public_gateway.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "public-gw-eg"
      namespace = kubernetes_namespace.envoy_gateway[0].id
    }
    spec = {
      gatewayClassName = "envoy-gateway-public"
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
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  (local.public_gw_eg_exposure_label.key) = local.public_gw_eg_exposure_label.value
                }
              }
            }
          }
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              name = local.public_gw_eg_wildcard_cert_secret
            }]
          }
        },
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.envoy_gateway_class_public,
    helm_release.alb_ingress,
    helm_release.public_gw_eg_tls,
    # Provisions a Service of type LoadBalancer via the Envoy Gateway
    # controller. The drain gate keeps both controllers alive long enough to
    # garbage collect it on destroy -- see networking-ingress.tf.
    time_sleep.controller_drain,
  ]
}

#------------------------------------------------------------------------------
# HTTP→HTTPS redirector for the public gateway. Mirror of the private one.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "public_gateway_eg_https_redirect" {
  count = var.envoy_gateway.enabled && var.envoy_gateway.public_gateway.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "public-gw-eg-https-redirect"
      namespace = kubernetes_namespace.envoy_gateway[0].id
    }
    spec = {
      parentRefs = [{
        name        = kubernetes_manifest.public_gateway_eg[0].manifest.metadata.name
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
    kubernetes_manifest.public_gateway_eg,
  ]
}

#------------------------------------------------------------------------------
# TLS for `public-gw-eg`: wildcard `*.binbash.com.ar`, issued by the same
# ClusterIssuer as the private wildcard (second solver — see
# networking-cluster-issuer.tf).
#
# The apex `binbash.com.ar` is deliberately NOT in `dnsNames`: nothing in this
# cluster serves the apex, and leaving it out keeps the ACME validation off the
# corporate root record. Add it here if that ever changes.
#------------------------------------------------------------------------------
resource "helm_release" "public_gw_eg_tls" {
  count = var.envoy_gateway.enabled && var.envoy_gateway.public_gateway.enabled && var.certmanager.enabled ? 1 : 0

  name       = "public-gw-eg-tls"
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
          name: public-gw-eg-wildcard
          namespace: ${kubernetes_namespace.envoy_gateway[0].id}
        spec:
          secretName: ${local.public_gw_eg_wildcard_cert_secret}
          issuerRef:
            kind: ClusterIssuer
            name: ${local.shared_clusterissuer_name}
          commonName: "*.${local.public_base_domain}"
          dnsNames:
            - "*.${local.public_base_domain}"
    EOF
  ]

  depends_on = [
    helm_release.cluster_issuer_binbash_aws,
  ]
}
