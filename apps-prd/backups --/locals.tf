locals {
  tags = {
    Name        = "backups"
    Terraform   = "true"
    Environment = var.environment
  }
}