resource "kubernetes_namespace" "monitoring" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "monitoring"
  }
}
