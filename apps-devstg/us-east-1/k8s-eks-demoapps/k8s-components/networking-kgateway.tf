#------------------------------------------------------------------------------
# kgateway (CNCF, formerly Gloo Gateway)
# -----------------------------------------------------------------------------
# Test drive as a future replacement for nginx-ingress. kgateway implements
# the Kubernetes Gateway API on top of Envoy. It coexists with nginx-ingress
# since it consumes Gateway / HTTPRoute resources rather than Ingress ones.
#
# Install order (enforced via depends_on below):
#   1. Upstream Gateway API CRDs (standard channel)
#   2. kgateway CRDs (kgateway-specific CRDs like GatewayParameters, etc.)
#   3. kgateway controller
#
# Docs: https://kgateway.dev/docs/envoy/latest/quickstart/
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# 1. Gateway API CRDs (upstream, standard channel).
# Fetched from the pinned GitHub release and applied as individual manifests.
#------------------------------------------------------------------------------
data "http" "gateway_api_crds" {
  count = var.kgateway.enabled ? 1 : 0
  url   = local.gateway_api_crds_url
}

locals {
  # Split the multi-document YAML into individual docs and keep only valid
  # ones (drops comments, blank chunks, and any stray document separators).
  # Keyed by resource name so the for_each map is stable across plans.
  # The upstream YAML carries a `status: {}` stub on each CRD that the
  # kubernetes_manifest provider forbids (server-managed field), so strip it.
  _gateway_api_crds_body = try(data.http.gateway_api_crds[0].response_body, "")
  gateway_api_crd_manifests = {
    for doc in [
      for chunk in split("\n---\n", local._gateway_api_crds_body) :
      try(yamldecode(chunk), null)
      ] : doc.metadata.name => {
      for k, v in doc : k => v if k != "status"
    } if doc != null && try(doc.kind, "") != ""
  }
}

resource "kubernetes_manifest" "gateway_api_crds" {
  for_each = local.gateway_api_crd_manifests
  manifest = each.value
}

#------------------------------------------------------------------------------
# 2. kgateway CRDs (kgateway-specific resources).
#------------------------------------------------------------------------------
resource "helm_release" "kgateway_crds" {
  count            = var.kgateway.enabled ? 1 : 0
  name             = "kgateway-crds"
  namespace        = kubernetes_namespace.kgateway[0].id
  repository       = "oci://cr.kgateway.dev/kgateway-dev/charts"
  chart            = "kgateway-crds"
  version          = var.kgateway.version
  create_namespace = false

  depends_on = [
    kubernetes_manifest.gateway_api_crds,
  ]
}

#------------------------------------------------------------------------------
# 3. kgateway controller.
#------------------------------------------------------------------------------
resource "helm_release" "kgateway" {
  count            = var.kgateway.enabled ? 1 : 0
  name             = "kgateway"
  namespace        = kubernetes_namespace.kgateway[0].id
  repository       = "oci://cr.kgateway.dev/kgateway-dev/charts"
  chart            = "kgateway"
  version          = var.kgateway.version
  create_namespace = false

  values = [
    templatefile("chart-values/kgateway.yaml", {
      nodeSelector         = local.tools_nodeSelector
      tolerations          = local.tools_tolerations
      experimentalFeatures = var.kgateway.experimental_features
    })
  ]

  depends_on = [
    helm_release.kgateway_crds,
  ]
}

#------------------------------------------------------------------------------
# Shared private Gateway (`private-gw`)
# -----------------------------------------------------------------------------
# Platform-shared L7 entry point for VPN-only traffic. kgateway provisions an
# Envoy Deployment + Service for this Gateway; the AWS Load Balancer Controller
# (LBC) — see helm_release.alb_ingress in networking-ingress.tf — picks up the
# infrastructure.annotations and provisions an internal NLB targeting pod IPs
# directly (target-type=ip). Workloads attach via HTTPRoute.parentRef from any
# namespace (allowedRoutes.namespaces.from = "All").
#
# Modern annotation set (vs. the legacy in-tree `aws-load-balancer-type: nlb`):
#   - `type: external`          tells the in-tree provider to stay out of it
#   - `nlb-target-type: ip`     register pod ENIs directly, no NodePort hop
#   - `scheme: internal`        private subnets only
# This is what makes the LB reachable from the VPN out of the box: LBC creates
# a security group on the NLB and adds an ingress rule to the cluster SG, so
# no per-source rule on the worker-node SG is needed.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "private_gateway" {
  count = var.kgateway.enabled && var.kgateway.private_gateway.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "private-gw"
      namespace = kubernetes_namespace.kgateway[0].id
    }
    spec = {
      gatewayClassName = "kgateway"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
          allowedRoutes = {
            namespaces = { from = "All" }
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
              name = local.private_gw_wildcard_cert_secret
            }]
          }
        },
      ]
      infrastructure = {
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
          "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internal"
        }
        # Pin the auto-provisioned Envoy data-plane Deployment to the tools
        # node group, alongside the kgateway controller and other platform
        # controllers. The apps node hits VPC-CNI pod-density limits quickly,
        # which left the Envoy pod Pending after the HTTPS-listener rolling
        # update. Tools node has the `stack: tools` taint, so we toleratе it
        # via GatewayParameters.
        parametersRef = {
          group = "gateway.kgateway.dev"
          kind  = "GatewayParameters"
          name  = kubernetes_manifest.private_gateway_params[0].manifest.metadata.name
        }
      }
    }
  }

  depends_on = [
    helm_release.kgateway,
    helm_release.alb_ingress,
    helm_release.private_gw_tls,
    kubernetes_manifest.private_gateway_params,
  ]
}

#------------------------------------------------------------------------------
# GatewayParameters: scheduling override for the kgateway-provisioned Envoy
# data-plane Deployment for `private-gw`. Lands the proxy on the `stack: tools`
# node group (consistent with kgateway controller and other platform pods).
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "private_gateway_params" {
  count = var.kgateway.enabled && var.kgateway.private_gateway.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.kgateway.dev/v1alpha1"
    kind       = "GatewayParameters"
    metadata = {
      name      = "private-gw-params"
      namespace = kubernetes_namespace.kgateway[0].id
    }
    spec = {
      kube = {
        podTemplate = {
          nodeSelector = { stack = "tools" }
          tolerations = [{
            key      = "stack"
            operator = "Equal"
            value    = "tools"
            effect   = "NoSchedule"
          }]
        }
      }
    }
  }

  depends_on = [
    helm_release.kgateway,
  ]
}

#------------------------------------------------------------------------------
# TLS for `private-gw`: wildcard `*.aws.binbash.com.ar` Let's Encrypt cert.
# -----------------------------------------------------------------------------
# How this works (despite `aws.binbash.com.ar` being a private-only zone):
# `aws.binbash.com.ar` has NO public NS delegation, so public DNS queries for
# `_acme-challenge.<host>.aws.binbash.com.ar` resolve up the chain to the
# `binbash.com.ar` NS servers. cert-manager (with public-zone-only IAM) writes
# the ACME TXT into the public `binbash.com.ar` zone; LE's public validators
# read it from there. This mirrors the existing nginx-ingress flow.
#
# We pin `dns01.route53.hostedZoneID` to the public zone — otherwise cert-manager
# would auto-discover the longer-suffix-match private zone and fail to write
# (the IRSA role has no perms there).
#
# The bundle is rendered through binbashar/raw rather than `kubernetes_manifest`
# so we sidestep plan-time CRD discovery for cert-manager CRDs (same pattern
# already used by `helm_release.cluster_secrets_manager` in security.tf).
#------------------------------------------------------------------------------
locals {
  private_gw_wildcard_cert_secret = "private-gw-wildcard-tls"
  private_gw_clusterissuer_name   = "clusterissuer-binbash-aws"
}

resource "helm_release" "private_gw_tls" {
  count = var.kgateway.enabled && var.kgateway.private_gateway.enabled && var.certmanager.enabled ? 1 : 0

  name       = "private-gw-tls"
  namespace  = kubernetes_namespace.kgateway[0].id
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "raw"
  version    = "0.1.0"

  values = [
    <<-EOF
    resources:
      - apiVersion: cert-manager.io/v1
        kind: ClusterIssuer
        metadata:
          name: ${local.private_gw_clusterissuer_name}
        spec:
          acme:
            server: https://acme-v02.api.letsencrypt.org/directory
            email: info@binbash.com.ar
            privateKeySecretRef:
              name: ${local.private_gw_clusterissuer_name}-account-key
            solvers:
              - selector:
                  dnsZones:
                    - ${local.private_base_domain}
                dns01:
                  route53:
                    region: ${var.region}
                    hostedZoneID: ${data.terraform_remote_state.shared-dns.outputs.aws_public_zone_id}
      - apiVersion: cert-manager.io/v1
        kind: Certificate
        metadata:
          name: private-gw-wildcard
          namespace: ${kubernetes_namespace.kgateway[0].id}
        spec:
          secretName: ${local.private_gw_wildcard_cert_secret}
          issuerRef:
            kind: ClusterIssuer
            name: ${local.private_gw_clusterissuer_name}
          commonName: ${local.private_base_domain}
          dnsNames:
            - ${local.private_base_domain}
            - "*.${local.private_base_domain}"
    EOF
  ]

  depends_on = [
    helm_release.certmanager,
  ]
}
