#------------------------------------------------------------------------------
# External DNS (Private): Sync ingresses hosts with your DNS server.
#------------------------------------------------------------------------------
resource "helm_release" "externaldns_private" {
  count = var.dns_sync.private.enabled ? 1 : 0

  # depends_on = [null_resource.download]

  name       = "externaldns-private"
  namespace  = kubernetes_namespace.externaldns[0].id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "6.38.0"
  values = [
    templatefile("chart-values/externaldns.yaml", {
      filteredDomain = local.private_base_domain
      filteredZoneId = data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_id
      txtOwnerId     = "${local.environment}-eks-demo-prv"
      # Watch Ingresses (nginx path) and, when a Gateway API data plane is
      # enabled, Gateway API HTTPRoutes too. Watching `gateway-httproute`
      # without its CRD installed makes the controller fatally crash, so gate
      # it on the Gateway API consumers (OR them if more are ever added).
      # Drop the Ingress-class annotation filter — it would silently exclude all
      # HTTPRoutes (which don't carry the kubernetes.io/ingress.class annotation).
      # Domain filtering above already scopes records to aws.binbash.com.ar.
      sources          = var.envoy_gateway.enabled ? ["ingress", "gateway-httproute"] : ["ingress"]
      annotationFilter = ""
      # Nothing to exclude: `aws.binbash.com.ar` has no subdomains carved out
      # for another release. The reverse is not true — see the public release.
      excludeDomains     = []
      zoneType           = "private"
      serviceAccountName = "externaldns-private"
      roleArn            = data.terraform_remote_state.cluster-identities.outputs.private_externaldns_role_arn
    })
  ]
}

#------------------------------------------------------------------------------
# External DNS (Public): Sync ingresses hosts with your DNS server.
#
# Two knobs flip once the public Envoy Gateway is enabled:
#
#   - `sources` gains `gateway-httproute`, so HTTPRoutes attached to
#     `public-gw-eg` get a record in the public zone (external-dns resolves the
#     target from the parent Gateway's status address, i.e. the public NLB).
#
#   - `annotationFilter` is dropped. It filtered on
#     `kubernetes.io/ingress.class=public-apps`, and annotation filters apply
#     across every source — keeping it would silently exclude all HTTPRoutes,
#     which carry no ingress-class annotation. Scoping then falls to
#     `domainFilters` + `excludeDomains`, which is precise here because public
#     and private hostnames live in disjoint domains by convention
#     (`<app>.binbash.com.ar` vs `<app>.aws.binbash.com.ar`).
#------------------------------------------------------------------------------
resource "helm_release" "externaldns_public" {
  count = var.dns_sync.public.enabled ? 1 : 0

  name       = "externaldns-public"
  namespace  = kubernetes_namespace.externaldns[0].id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "6.38.0"
  values = [
    templatefile("chart-values/externaldns.yaml", {
      filteredDomain = local.public_base_domain
      filteredZoneId = data.terraform_remote_state.shared-dns.outputs.aws_public_zone_id
      txtOwnerId     = "${local.environment}-eks-demo-pub"
      sources = var.envoy_gateway.enabled && var.envoy_gateway.public_gateway.enabled ? [
        "ingress", "gateway-httproute"
      ] : ["ingress"]
      annotationFilter = var.envoy_gateway.enabled && var.envoy_gateway.public_gateway.enabled ? "" : (
        "kubernetes.io/ingress.class=${local.public_ingress_class}"
      )
      excludeDomains     = [local.private_base_domain]
      zoneType           = "public"
      serviceAccountName = "externaldns-public"
      roleArn            = data.terraform_remote_state.cluster-identities.outputs.public_externaldns_role_arn
    })
  ]
}
