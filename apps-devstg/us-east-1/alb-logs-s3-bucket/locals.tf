locals {
  bucket_name = "${var.project}-${var.environment}-alb"

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}