# Test: Leverage CLI 2.2.0rc5 workflow validation with common.tfvars fix
locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}
