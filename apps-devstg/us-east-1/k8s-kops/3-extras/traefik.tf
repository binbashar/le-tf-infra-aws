resource "kubernetes_namespace" "traefik" {
  count = var.traefik ? 1 : 0

  metadata {
    labels = local.labels
    name   = "traefik"
  }
}
resource "helm_release" "traefik" {
  count      = var.traefik ? 1 : 0
  name       = "traefik"
  namespace  = kubernetes_namespace.traefik[0].id
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "v28.0.0"
  values     = [file("chart-values/traefik.yaml")]

  depends_on = [kubernetes_namespace.traefik]
}
