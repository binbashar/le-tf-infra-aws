locals {
  name = "${var.project}-${var.environment}-data-lake-demo"

  tags = {
    Name        = local.name
    Terraform   = "true"
    Environment = var.environment
  }
}
