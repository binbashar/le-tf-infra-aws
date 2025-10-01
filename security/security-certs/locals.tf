locals {
  # Removing apps- from domain
  environment = replace(var.environment, "apps-", "")
  tags = {
    Terraform   = "true"
    Layer       = "security-certs"
    Environment = var.environment
    Layer       = local.layer_name
  }
}
