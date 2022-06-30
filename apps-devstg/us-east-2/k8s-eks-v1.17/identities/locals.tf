locals {
  environment = replace(var.environment, "-", "")
  prefix      = "${local.environment}-dr"
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}