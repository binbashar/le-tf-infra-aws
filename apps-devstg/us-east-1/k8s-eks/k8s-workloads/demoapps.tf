#------------------------------------------------------------------------------
# linkerd emojivoto demo application
#------------------------------------------------------------------------------
resource "helm_release" "emojivoto" {
  count      = lookup(var.demoapps, "emojivoto", false) ? 1 : 0
  name       = "emojivoto"
  namespace  = "argocd"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "argocd-application"
  version    = "0.2.0"
  values     = [file("chart-values/demoapps-emojivoto.yaml")]
}

#------------------------------------------------------------------------------
# google microservices demo
#------------------------------------------------------------------------------
resource "helm_release" "gmd" {
  count      = lookup(var.demoapps, "gdm", false) ? 1 : 0
  name       = "gmd"
  namespace  = "argocd"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "argocd-application"
  version    = "0.2.0"
  values     = [file("chart-values/demoapps-gmd.yaml")]
}

#------------------------------------------------------------------------------
# weave sock-shop microservices demo
#------------------------------------------------------------------------------
resource "helm_release" "sockshop" {
  count      = lookup(var.demoapps, "sockshop", false) ? 1 : 0
  name       = "sockshop"
  namespace  = "argocd"
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "argocd-application"
  version    = "0.2.0"
  values = [
    templatefile("chart-values/demoapps-sockshop.yaml", {
      accountid = var.accounts.shared.id,
      region    = var.region
    })
  ]
}
