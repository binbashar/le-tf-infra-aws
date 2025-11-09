#------------------------------------------------------------------------------
# Cert-Manager: Automatically get Let's Encrypt certificate for your ingress.
#------------------------------------------------------------------------------
resource "helm_release" "cert_manager" {
  count      = var.enable_cert_manager ? 1 : 0
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.id
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.19.0"
  values = [
    templatefile("chart-values/certmanager.yaml",
      {
        roleArn = "arn:aws:iam::${var.accounts.shared.id}:role/demoapps-cert-manager"
      }
    )
  ]
}

#------------------------------------------------------------------------------
# Cert-Manager Cluster Issuer: Certificate issuer for Binbash domains.
#------------------------------------------------------------------------------
resource "helm_release" "clusterissuer_binbash" {
  count      = var.enable_cert_manager ? 1 : 0
  name       = "clusterissuer-binbash"
  namespace  = kubernetes_namespace.cert_manager.id
  repository = "https://binbashar.github.io/helm-charts/"
  chart      = "cert-manager-clusterissuer"
  version    = "0.3.0"
  values     = [file("chart-values/clusterissuer-binbash.yaml")]
  depends_on = [helm_release.cert_manager]
}

