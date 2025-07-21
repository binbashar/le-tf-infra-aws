locals {
  name = "${var.project}-${var.environment}"
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}
