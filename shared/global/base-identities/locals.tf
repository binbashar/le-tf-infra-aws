locals {
  environment = replace(var.environment, "-", "")
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
