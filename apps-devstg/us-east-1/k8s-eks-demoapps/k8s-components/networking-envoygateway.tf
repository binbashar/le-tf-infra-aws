#------------------------------------------------------------------------------
# Envoy Gateway (CNCF, Envoy maintainers' official Gateway API implementation)
# -----------------------------------------------------------------------------
# The Gateway API data plane for this layer and the chosen replacement for
# nginx-ingress, picked over kgateway after benchmarking all three (see
# loadtest/test-results.md). Runs alongside nginx-ingress during the
# migration: EG reconciles Gateway API resources, nginx reconciles Ingress
# ones, so the two never contend. EG only reconciles Gateways whose
# `gatewayClassName` resolves to a GatewayClass carrying its own controller
# string, which is what kept it partitioned from kgateway while both ran.
#
# Install order (enforced via depends_on):
#   1. Upstream Gateway API CRDs (provided by networking-gateway-api.tf)
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
# same pattern as the Gateway API CRDs in networking-gateway-api.tf.
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
# Platform-shared L7 entry point for VPN-only traffic. An AWS LBC-managed
# internal NLB (target-type=instance) fronts the EG-provisioned Envoy Service.
# Workloads attach via HTTPRoute.parentRef from any namespace
# (allowedRoutes.namespaces.from = "All" on the https listener).
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# EnvoyProxy: parameters consumed by the GatewayClass below. Carries node
# scheduling for the EG-provisioned Envoy data-plane Deployment + the three
# AWS LBC annotations that turn the auto-created Service into an internal
# NLB targeting pod IPs directly.
#
# IMPORTANT: EG references EnvoyProxy at the GatewayClass level (via
# `spec.parametersRef`), not at the Gateway level. Every Gateway that needs
# different infra parameters therefore needs its own GatewayClass — which is
# exactly why the public gateway further down carries a second
# GatewayClass/EnvoyProxy pair rather than reusing this one.
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
          # target-type `instance` (NLB -> worker NodePort -> pod), not `ip`.
          #
          # This exists to preserve the client IP, ahead of moving
          # `echo-server.aws.binbash.com.ar` off nginx-ingress onto this
          # gateway. On `ip` target groups AWS defaults
          # `preserve_client_ip.enabled` to false for TCP, so Envoy sees the
          # connection as coming from the NLB and writes *that* into
          # `X-Forwarded-For` — blinding anything downstream that keys on
          # client IP. On `instance` target groups AWS preserves the source IP
          # and it cannot be disabled, so there is no companion attribute to
          # set; the target-type alone is the fix.
          #
          # Requires `externalTrafficPolicy: Local` or kube-proxy SNATs the
          # source away again. Envoy Gateway already defaults the provisioned
          # Service to `Local`, so nothing to set here — but do not assume that
          # if the EG version changes.
          #
          # The trade this was expected to carry turned out not to exist.
          # `loadtest/test-results.md` had found a small, repeatable client-side
          # timeout tail (0.04-0.11%) on nginx's `instance`-target NLB that
          # never appeared on either `ip`-target path, and attributed it to the
          # extra NodePort / target-health layer. S6 in that document is the
          # controlled test: with both data planes on identical `instance`
          # plumbing, Envoy logged zero failures over 450 k requests while nginx
          # logged 425. The tail was nginx's, not the target-type's. Nothing to
          # revisit here — `ip` + `preserve_client_ip.enabled=true` and PROXY
          # protocol v2 with EG `clientIPDetection` are both strictly more
          # moving parts for the same result.
          #
          # NOTE: `instance` does NOT bring back `X-Real-Ip`,
          # `X-Forwarded-Host`, `X-Forwarded-Port` or `X-Scheme`. Those are
          # nginx synthesising headers Envoy does not emit, and no target-type
          # changes that.
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
# GatewayClass: cluster-scoped, named `envoy-gateway`. Pinned to EG's
# controller string; parametersRef points at the EnvoyProxy above.
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
    # Provisions a Service of type LoadBalancer via the Envoy Gateway
    # controller. The drain gate keeps both controllers alive long enough to
    # garbage collect it on destroy -- see networking-ingress.tf.
    time_sleep.controller_drain,
  ]
}

#------------------------------------------------------------------------------
# Platform-shared HTTP→HTTPS redirector. Pinned to the http listener via
# sectionName; matches all paths; 301 (Gateway API rejects nginx's default
# 308). App HTTPRoutes don't opt in — the http listener refuses their
# attachment by namespace policy, so they reach the data plane only via 443.
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
# TLS for `private-gw-eg`: wildcard `*.aws.binbash.com.ar` Certificate in the
# EG namespace, issued by the cluster-scoped ClusterIssuer (see
# `helm_release.cluster_issuer_binbash_aws` in networking-cluster-issuer.tf).
#
# DNS01 works despite `aws.binbash.com.ar` being a private-only zone: it has
# no public NS delegation, so public lookups for `_acme-challenge.<host>`
# resolve up the chain to the `binbash.com.ar` NS servers. cert-manager writes
# the ACME TXT into the public zone (where its IRSA role has perms) and LE's
# public validators read it from there. Same trick as the nginx-ingress flow.
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

#------------------------------------------------------------------------------
# Shared public Gateway (`public-gw-eg`)
# -----------------------------------------------------------------------------
# Internet-facing counterpart of `private-gw-eg`. Same shape (EnvoyProxy ->
# GatewayClass -> Gateway -> HTTP→HTTPS redirect -> wildcard cert), with three
# deliberate differences:
#
#   1. The NLB is `internet-facing` and lands in the VPC's public subnets
#      (tagged `kubernetes.io/role/elb` by the network sublayer). Targets are
#      the worker nodes in the private subnets, same as the private gateway.
#
#   2. Access is restricted to `var.envoy_gateway_public_allowed_cidrs` at the
#      NLB's security group, not at L7. The allowlist sits on the NLB's own
#      frontend security group and is evaluated on inbound client traffic
#      before the load balancer forwards anything, so disallowed traffic never
#      reaches a pod (and is not billed). This is independent of target-type —
#      see the note on `nlb-target-type` below for why preserving the client IP
#      does not disturb it.
#
#   3. `allowedRoutes` on the HTTPS listener is a label Selector, not `All`.
#      A namespace has to be explicitly labelled (see
#      `local.public_gw_eg_exposure_label`) before anything in it can attach an
#      HTTPRoute — writing an HTTPRoute is not, by itself, enough to publish a
#      workload to the internet.
#
# Hostname scheme: `<app>.binbash.com.ar` (public zone), vs
# `<app>.aws.binbash.com.ar` on the private gateway.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# EnvoyProxy for the public data plane. Identical node scheduling to the
# private one; the LBC annotations differ in `scheme` and add the source-range
# allowlist.
#
# On `load-balancer-source-ranges`: when
# `service.beta.kubernetes.io/aws-load-balancer-security-groups` is absent the
# LBC creates and manages a frontend security group for the NLB, and renders
# this annotation into its ingress rules. If the annotation were omitted the
# LBC would default the group to 0.0.0.0/0 — hence the precondition below,
# which fails the plan rather than silently publishing an open endpoint. It
# lives here rather than as a variable validation so it only fires when the
# public gateway is actually being provisioned.
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
          # target-type `instance`, matching the private gateway. Both data
          # planes now preserve the client IP; see the long note on the private
          # EnvoyProxy above for the mechanics.
          #
          # This was deliberately left on `ip` when the private gateway moved,
          # on the theory that preserving the client IP would break the CIDR
          # allowlist: with preservation on, packets arrive at the node with the
          # client's address as the source, so any node-side rule written as a
          # CIDR would no longer match the NLB. That theory does not apply here,
          # for two independent reasons:
          #
          #   - The allowlist is not a node-side rule. It lives on the NLB's own
          #     frontend security group (`k8s-<ns>-<svc>-<hash>`, created by the
          #     LBC from `load-balancer-source-ranges`) and is evaluated on
          #     inbound client traffic at the load balancer. Nothing downstream
          #     of the NLB participates in it, so the target-type is irrelevant
          #     to it.
          #   - The node-side rule the LBC does write is a *security group
          #     reference*, not a CIDR: it allows the shared backend group
          #     `k8s-traffic-<cluster>-<hash>`, which the LBC attaches to the
          #     NLB itself. AWS documents security group referencing as working
          #     "even if you enable client IP preservation", and the private
          #     gateway has been running on exactly that combination since Day 4.
          #
          # So the allowlist keeps working unchanged and does not need to be
          # duplicated onto the node security group.
          #
          # Two consequences worth knowing:
          #   - `externalTrafficPolicy: Local` (EG's default, already set) means
          #     only nodes running a public Envoy pod pass the health check.
          #     With the `tools` node group at desired = 1 that is a single
          #     point of failure — the same one the private gateway already
          #     accepted deliberately for this disposable cluster.
          #   - Envoy now sees the real client address, which makes L7 CIDR
          #     matching (SecurityPolicy `principal.clientCIDRs`) viable without
          #     proxy protocol v2. Not used today — the security group is
          #     cheaper and drops traffic earlier — but it is now an option for
          #     the WAF question.
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
# The public Gateway.
# - `http` listener: namespaces.from = "Same", so only the redirect HTTPRoute
#   below attaches — app routes are HTTPS-only by construction, same as the
#   private gateway.
# - `https` listener: namespaces.from = "Selector". See point 3 in the section
#   header — this is the opt-in gate for internet exposure.
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
