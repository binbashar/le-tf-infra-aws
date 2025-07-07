#resource "kubernetes_namespace" "externaldns" {
#  count    = var.externaldns ? 1 : 0
#
#  metadata {
#    labels = local.labels
#    name   = "externaldns"
#  }
#}
#
#resource "helm_release" "externaldns_public" {
#  count      = var.externaldns ? 1 : 0
#
#  name       = "externaldns-public"
#  namespace  = kubernetes_namespace.externaldns[0].id
#  repository = "https://charts.bitnami.com/bitnami"
#  chart      = "external-dns"
#  version    = "6.14.4"
#  values = [
#    templatefile("chart-values/externaldns.yaml", {
#      filteredDomain     = "costenginetool.binbash.co"
#      filteredZoneId     = data.terraform_remote_state.shared-dns.outputs.aws_public_zone_id[0]
#      txtOwnerId         = "${var.environment}-kops-pub"
#      #annotationFilter   = "kubernetes.io/ingress.class=${local.public_ingress_class}"
#      zoneType           = "public"
#      serviceAccountName = "externaldns-public"
#      #roleArn            = data.terraform_remote_state.eks-identities.outputs.public_externaldns_role_arn
#    })
#  ]
#
#  depends_on = [kubernetes_namespace.externaldns]
#}
