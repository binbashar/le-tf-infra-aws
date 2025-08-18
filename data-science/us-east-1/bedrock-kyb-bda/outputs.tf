output "input_bucket_name" {
  description = "Name of the S3 bucket for KYB document input"
  value       = aws_s3_bucket.kyb_input.bucket
}

output "input_bucket_arn" {
  description = "ARN of the S3 bucket for KYB document input"
  value       = aws_s3_bucket.kyb_input.arn
}

output "output_bucket_name" {
  description = "Name of the S3 bucket for processed KYB output"
  value       = aws_s3_bucket.kyb_output.bucket
}

output "output_bucket_arn" {
  description = "ARN of the S3 bucket for processed KYB output"
  value       = aws_s3_bucket.kyb_output.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function that processes KYB documents"
  value       = aws_lambda_function.kyb_bda_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function that processes KYB documents"
  value       = aws_lambda_function.kyb_bda_processor.arn
}

output "bda_project_name" {
  description = "Name of the Bedrock Data Automation project"
  value       = awscc_bedrock_data_automation_project.kyb_project.project_name
}

output "bda_project_arn" {
  description = "ARN of the Bedrock Data Automation project"
  value       = awscc_bedrock_data_automation_project.kyb_project.project_arn
}

output "kyb_blueprint_name" {
  description = "Name of the KYB custom blueprint"
  value       = awscc_bedrock_blueprint.kyb_blueprint.blueprint_name
}

output "kyb_blueprint_arn" {
  description = "ARN of the KYB custom blueprint"
  value       = awscc_bedrock_blueprint.kyb_blueprint.blueprint_arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule for S3 triggers"
  value       = aws_cloudwatch_event_rule.s3_trigger.name
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule for S3 triggers"
  value       = aws_cloudwatch_event_rule.s3_trigger.arn
}

output "dead_letter_queue_url" {
  description = "URL of the dead letter queue for failed processing"
  value       = aws_sqs_queue.dlq.url
}

output "dead_letter_queue_arn" {
  description = "ARN of the dead letter queue for failed processing"
  value       = aws_sqs_queue.dlq.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

# Bedrock Data Automation uses service-linked roles, no custom role needed