locals {
  region = "us-east-1"
  name   = "${var.project}-${var.environment}-lake-house-demo"

  tags = {
    Name        = local.name
    Terraform   = "true"
    Environment = var.environment
  }
}
