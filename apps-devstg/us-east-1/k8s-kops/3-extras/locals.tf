locals {
  labels = {
    environment                    = var.environment
    "app.kubernetes.io/managed-by" = "Terraform"
    "app.kubernetes.io/part-of"    = var.environment
  }
}
