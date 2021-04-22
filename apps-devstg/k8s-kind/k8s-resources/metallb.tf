#------------------------------------------------------------------------------
# MetalLB for kind
#------------------------------------------------------------------------------
resource "helm_release" "metallb" {
  count      = var.kind["metallb"] ? 1 : 0
  name       = "metallb"
  namespace  = kubernetes_namespace.metallb.id
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metallb"
  version    = "2.3.6"
  values     = [file("chart-values/metallb.yaml")]
}
