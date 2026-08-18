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
# The Service this renders depends on `public_gateway.frontend`:
#
#   nlb — type LoadBalancer. The annotations below make the LBC provision an
#         internet-facing NLB and render `load-balancer-source-ranges` into the
#         frontend security group it manages. Omit that annotation and the LBC
#         defaults the group to 0.0.0.0/0 — hence the precondition, which fails
#         the plan instead of silently publishing an open endpoint.
#
#   alb — type ClusterIP, no annotations, no Service-provisioned load balancer.
#         `kubernetes_ingress_v1.envoy_apps` in networking-ingress.tf asks the
#         LBC for an ALB pointing at this Service instead, and carries the same
#         allowlist as `inbound-cidrs` plus its own copy of the precondition.
#
# `envoyService.name` is pinned so the Ingress can reference the Service by a
# known name: left to itself EG derives `envoy-<ns>-<gateway>-<hash>`, which is
# stable but not knowable at write time.
#
# On `nlb-target-type: instance` — this was held back on `ip` at first, on the
# theory that preserving the client IP would break the CIDR allowlist. It does
# not, for two independent reasons: the allowlist lives on the NLB's own
# frontend SG and is evaluated before the LB forwards anything, and the
# node-side rule the LBC writes is a security-group *reference* to the shared
# backend group, which AWS documents as working "even if you enable client IP
# preservation". So it needs no duplication onto the node SG.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "public_gw_eg_proxy" {
  count = local.public_gw_eg_enabled ? 1 : 0

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
          # `annotations` is merged in rather than set to `{}` under the ALB
          # frontend: the provider serialises an empty map as `null`, which the
          # CRD rejects ("must be of type object"). Omitting the key is the only
          # way to say "no annotations".
          envoyService = merge(
            {
              name = local.public_gw_eg_svc_name
              type = local.public_gw_eg_on_alb ? "ClusterIP" : "LoadBalancer"
            },
            local.public_gw_eg_on_alb ? {} : {
              annotations = {
                "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
                "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
                "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
                "service.beta.kubernetes.io/load-balancer-source-ranges"       = join(",", local.public_gw_eg_source_ranges)
              }
            },
          )
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.envoy_gateway.public_gateway.open_to_internet || length(var.envoy_gateway_public_allowed_cidrs) > 0
      error_message = "envoy_gateway_public_allowed_cidrs must not be empty while the public gateway is enabled and `open_to_internet` is false: the AWS Load Balancer Controller would default the load balancer's security group to 0.0.0.0/0 anyway — as an accident rather than a decision. Either set the list in allowlist.local.auto.tfvars (see allowlist.local.auto.tfvars.example), or set `open_to_internet = true` to say the perimeter is open on purpose."
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
# The public Gateway. Both listeners use a label Selector rather than `All`:
# this is the opt-in gate for internet exposure, so writing an HTTPRoute is not
# by itself enough to publish a workload — a cluster admin has to label the
# namespace first.
#
# Which listener actually carries public traffic depends on the frontend:
#
#   nlb — `https`, terminating the wildcard below. `http` exists only for the
#         redirector, which bounces everything to HTTPS.
#   alb — `http`. The ALB terminates TLS off its ACM certificate and forwards
#         cleartext, so this is the real public path and there is nothing to
#         redirect. `https` stays configured but unused — it is what a later
#         move to `backend-protocol: HTTPS` would need.
#
# `http` carries the Selector in both cases. Under `nlb` that is redundant
# (only the redirector attaches), but leaving the two listeners inconsistent
# would mean the gate silently disappears when the frontend flips.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "public_gateway_eg" {
  count = local.public_gw_eg_enabled ? 1 : 0

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
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  (local.public_gw_eg_exposure_label.key) = local.public_gw_eg_exposure_label.value
                }
              }
            }
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
#
# Only under the `nlb` frontend. With an ALB in front the redirect belongs on
# the ALB (`actions.ssl-redirect`, see networking-ingress.tf), which bounces the
# client before any traffic reaches the cluster. Leaving this attached as well
# would 301 every request the ALB forwards over its cleartext hop, sending
# clients into a loop.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "public_gateway_eg_https_redirect" {
  count = local.public_gw_eg_on_nlb ? 1 : 0

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

#------------------------------------------------------------------------------
# Health check target for the ALB frontend.
#
# An ALB health check needs a path that answers 200. Envoy has none to offer:
# a request that matches no route returns 404, so a health check against the
# data listener fails on an otherwise healthy gateway. This is not specific to
# Envoy Gateway — every Envoy-based ingress hits it, and each solves it the
# same way. Istio ships a dedicated endpoint on :15021; kgateway's own AWS ALB
# guide has you declare a route that answers with a fixed 200. This is that,
# using Envoy Gateway's `HTTPRouteFilter`.
#
# Deliberately on the data listener rather than Envoy's readiness endpoint
# (:19001/ready). Readiness reports whether the *process* is up; it stays green
# while the listener is broken, the certificate failed to load or the Gateway
# never reached `Programmed`. This path traverses the listener and the route
# engine, so a healthy check means the thing that serves traffic works.
#
# It answers 200 to anyone who asks. That is intentional and leaks nothing —
# a fixed response that touches no backend.
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Trust the ALB's forwarded headers.
#
# Without this Envoy treats the ALB as the client: it reports the ALB's pod-CIDR
# address as the origin and overwrites `X-Forwarded-Proto` with `http`, since
# the ALB→Envoy hop is cleartext. Two consequences, one cosmetic and one not:
#
#   - Any backend that builds self-referential URLs from `X-Forwarded-Proto`
#     emits `http://` links, and one that redirects to its own canonical URL
#     loops — the ALB sends the client back over HTTPS, Envoy tells the backend
#     it was HTTP, the backend redirects again.
#   - `SecurityPolicy` CIDR matching would compare against the ALB's address, so
#     a per-route IP allowlist would match everything or nothing.
#
# `numTrustedHops` covers both: upstream documents it as deciding the origin
# client's address *and* whether `x-forwarded-proto` is trusted. One hop,
# because exactly one proxy (the ALB) sits in front.
#
# Counting is from the right of the XFF Envoy receives, which is what makes it
# safe: a client that sends its own `X-Forwarded-For` gets the real address
# appended by the ALB to the right of the forgery, so the rightmost entry is
# still the address AWS observed.
#
# Scoped to the public Gateway, and only under the ALB frontend. The private
# Gateway must NOT get this: nothing sits in front of it, its NLB preserves the
# client address at L4, and trusting a client-supplied XFF there would let
# anyone claim any source IP.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "public_gw_eg_client_traffic_policy" {
  count = local.public_gw_eg_on_alb ? 1 : 0

  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "ClientTrafficPolicy"
    metadata = {
      name      = "public-gw-eg-trust-alb"
      namespace = kubernetes_namespace.envoy_gateway[0].id
    }
    spec = {
      targetRefs = [{
        group = "gateway.networking.k8s.io"
        kind  = "Gateway"
        name  = kubernetes_manifest.public_gateway_eg[0].manifest.metadata.name
      }]
      clientIPDetection = {
        xForwardedFor = {
          numTrustedHops = 1
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.public_gateway_eg,
  ]
}

resource "kubernetes_manifest" "public_gw_eg_healthz_filter" {
  count = local.public_gw_eg_on_alb ? 1 : 0

  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "HTTPRouteFilter"
    metadata = {
      name      = "public-gw-eg-healthz"
      namespace = kubernetes_namespace.envoy_gateway[0].id
    }
    spec = {
      directResponse = {
        statusCode = 200
        body = {
          type   = "Inline"
          inline = "ok"
        }
      }
    }
  }

  depends_on = [
    helm_release.envoy_gateway,
  ]
}

resource "kubernetes_manifest" "public_gw_eg_healthz_route" {
  count = local.public_gw_eg_on_alb ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "public-gw-eg-healthz"
      namespace = kubernetes_namespace.envoy_gateway[0].id
      annotations = {
        # Nothing here should reach DNS: the hostname is published by the ALB's
        # Ingress, and this route deliberately carries no hostname at all so it
        # answers on whatever Host the health check sends.
        "external-dns.alpha.kubernetes.io/controller" = "none"
      }
    }
    spec = {
      parentRefs = [{
        name        = kubernetes_manifest.public_gateway_eg[0].manifest.metadata.name
        sectionName = "http"
      }]
      rules = [{
        matches = [{
          path = {
            type  = "Exact"
            value = "/healthz"
          }
        }]
        filters = [{
          type = "ExtensionRef"
          extensionRef = {
            group = "gateway.envoyproxy.io"
            kind  = "HTTPRouteFilter"
            name  = kubernetes_manifest.public_gw_eg_healthz_filter[0].manifest.metadata.name
          }
        }]
      }]
    }
  }

  depends_on = [
    kubernetes_manifest.public_gateway_eg,
    kubernetes_manifest.public_gw_eg_healthz_filter,
  ]
}
