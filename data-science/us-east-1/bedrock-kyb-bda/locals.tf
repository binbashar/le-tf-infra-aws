locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Purpose     = "bedrock-kyb-bda"
    Layer       = "bedrock-kyb-bda"
    Service     = "bedrock-data-automation"
  }

  # Sanitized name prefix
  name_prefix = lower(replace("${var.project}-${var.environment}-kyb", "_", "-"))

  # Deterministic unique suffix based on account
  unique_suffix = substr(md5("${local.name_prefix}-${data.aws_caller_identity.current.account_id}"), 0, 6)

  # S3 bucket names with suffix and length limit
  input_bucket_name  = substr("${local.name_prefix}-input-${local.unique_suffix}", 0, 63)
  output_bucket_name = substr("${local.name_prefix}-output-${local.unique_suffix}", 0, 63)

  # Lambda function name
  lambda_function_name = "${var.project}-${var.environment}-kyb-bda-processor"

  # BDA Project name
  bda_project_name = "${var.project}-${var.environment}-kyb-project-v2"

  # EventBridge rule name
  eventbridge_rule_name = "${var.project}-${var.environment}-kyb-s3-trigger"

  # Bedrock Data Automation Profile ARN (hardcoded to us-east-1 to fix region mismatch)
  bda_profile_arn = "arn:aws:bedrock:us-east-1:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1"
}