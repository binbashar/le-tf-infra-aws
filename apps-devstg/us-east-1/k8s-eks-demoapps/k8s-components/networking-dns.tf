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
      filteredDomain     = local.private_base_domain
      filteredZoneId     = data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_id
      txtOwnerId         = "${local.environment}-eks-demo-prv"
      annotationFilter   = "kubernetes.io/ingress.class=${local.private_ingress_class}"
      zoneType           = "private"
      serviceAccountName = "externaldns-private"
      roleArn            = data.terraform_remote_state.cluster-identities.outputs.private_externaldns_role_arn
    })
  ]
}

#------------------------------------------------------------------------------
# External DNS (Public): Sync ingresses hosts with your DNS server.
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
      filteredDomain     = local.public_base_domain
      filteredZoneId     = data.terraform_remote_state.shared-dns.outputs.aws_public_zone_id
      txtOwnerId         = "${local.environment}-eks-demo-pub"
      annotationFilter   = "kubernetes.io/ingress.class=${local.public_ingress_class}"
      zoneType           = "public"
      serviceAccountName = "externaldns-public"
      roleArn            = data.terraform_remote_state.cluster-identities.outputs.public_externaldns_role_arn
    })
  ]
}
