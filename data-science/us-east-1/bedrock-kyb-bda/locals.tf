locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Purpose     = "bedrock-kyb-bda"
    Layer       = "bedrock-kyb-bda"
    Service     = "bedrock-data-automation"
  }

  # S3 bucket names
  input_bucket_name  = lower("${var.project}-${var.environment}-kyb-input")
  output_bucket_name = lower("${var.project}-${var.environment}-kyb-output")

  # Lambda function name
  lambda_function_name = "${var.project}-${var.environment}-kyb-bda-processor"

  # BDA Project name
  bda_project_name = "${var.project}-${var.environment}-kyb-project-v2"

  # EventBridge rule name
  eventbridge_rule_name = "${var.project}-${var.environment}-kyb-s3-trigger"

  # Bedrock Data Automation Profile ARN (hardcoded to us-east-1 to fix region mismatch)
  bda_profile_arn = "arn:aws:bedrock:us-east-1:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1"
}