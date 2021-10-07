locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
  vault_name = "${var.project}-${var.environment}-default"
}
