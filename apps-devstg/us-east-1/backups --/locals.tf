locals {
  tags = {
    Name        = "backups"
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}