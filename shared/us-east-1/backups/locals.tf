locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
  vault_name = "${var.project}-${var.environment}-default"
}
