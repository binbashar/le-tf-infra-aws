locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  # MWAA Configuration
  mwaa_name = "${var.project}-${var.environment}-airflow"

  # S3 bucket configuration
  s3_bucket_name = "${var.project}-${var.environment}-mwaa"
}
