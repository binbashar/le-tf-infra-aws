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
  bda_project_name = "${var.project}-${var.environment}-kyb-project"

  # EventBridge rule name
  eventbridge_rule_name = "${var.project}-${var.environment}-kyb-s3-trigger"
}