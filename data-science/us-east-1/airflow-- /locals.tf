locals {
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }

  # MWAA Configuration
  mwaa_name = "${var.project}-${var.environment}-airflow"

  # S3 bucket configuration
  s3_bucket_name = "${var.project}-${var.environment}-mwaa"
}
