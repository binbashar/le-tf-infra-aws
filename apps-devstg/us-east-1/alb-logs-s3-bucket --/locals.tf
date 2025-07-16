locals {
  bucket_name = "${var.project}-${var.environment}-alb"

  transition = [
    {
      days          = 30
      storage_class = "ONEZONE_IA"
    },
    {
      days          = 90
      storage_class = "GLACIER"
    }
  ]

  noncurrent_version_expiration_days = 90
  expiration_days                    = 180

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}