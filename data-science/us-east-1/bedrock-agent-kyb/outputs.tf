# Outputs will be added progressively as resources are created in tasks T-002 through T-012
# This ensures validation passes at each implementation stage

output "input_bucket_name" {
  description = "Name of the S3 bucket for input PDFs"
  value       = aws_s3_bucket.input.id
}

output "input_bucket_arn" {
  description = "ARN of the S3 bucket for input PDFs"
  value       = aws_s3_bucket.input.arn
}

output "processing_bucket_name" {
  description = "Name of the S3 bucket for BDA processing output"
  value       = aws_s3_bucket.processing.id
}

output "processing_bucket_arn" {
  description = "ARN of the S3 bucket for BDA processing output"
  value       = aws_s3_bucket.processing.arn
}

output "output_bucket_name" {
  description = "Name of the S3 bucket for final agent results"
  value       = aws_s3_bucket.output.id
}

output "output_bucket_arn" {
  description = "ARN of the S3 bucket for final agent results"
  value       = aws_s3_bucket.output.arn
}

output "bda_project_name" {
  description = "Name of the Bedrock Data Automation project"
  value       = awscc_bedrock_data_automation_project.kyb_agent.project_name
}

output "bda_project_arn" {
  description = "ARN of the Bedrock Data Automation project"
  value       = awscc_bedrock_data_automation_project.kyb_agent.project_arn
}

output "bda_invoker_function_name" {
  description = "Name of the BDA Invoker Lambda function"
  value       = aws_lambda_function.bda_invoker.function_name
}

output "bda_invoker_function_arn" {
  description = "ARN of the BDA Invoker Lambda function"
  value       = aws_lambda_function.bda_invoker.arn
}

output "agent_invoker_function_name" {
  description = "Name of the Agent Invoker Lambda function"
  value       = aws_lambda_function.agent_invoker.function_name
}

output "agent_invoker_function_arn" {
  description = "ARN of the Agent Invoker Lambda function"
  value       = aws_lambda_function.agent_invoker.arn
}

output "get_documents_function_name" {
  description = "Name of the GetDocuments Lambda function"
  value       = aws_lambda_function.get_documents.function_name
}

output "get_documents_function_arn" {
  description = "ARN of the GetDocuments Lambda function"
  value       = aws_lambda_function.get_documents.arn
}

output "save_document_function_name" {
  description = "Name of the SaveDocument Lambda function"
  value       = aws_lambda_function.save_document.function_name
}

output "save_document_function_arn" {
  description = "ARN of the SaveDocument Lambda function"
  value       = aws_lambda_function.save_document.arn
}

output "check_sanctions_function_name" {
  description = "Name of the CheckSanctions Lambda function"
  value       = aws_lambda_function.check_sanctions.function_name
}

output "check_sanctions_function_arn" {
  description = "ARN of the CheckSanctions Lambda function"
  value       = aws_lambda_function.check_sanctions.arn
}

output "input_trigger_rule_name" {
  description = "Name of the EventBridge rule for input bucket trigger"
  value       = aws_cloudwatch_event_rule.input_bucket_trigger.name
}

output "input_trigger_rule_arn" {
  description = "ARN of the EventBridge rule for input bucket trigger"
  value       = aws_cloudwatch_event_rule.input_bucket_trigger.arn
}

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = module.apigw_kyb_agent.aws_api_gateway_rest_api_id
}

output "api_gateway_endpoint" {
  description = "Invoke URL for the API Gateway endpoint"
  value       = "${module.apigw_kyb_agent.aws_api_gateway_stage_invoke_url}/invoke-agent"
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway (for Lambda permissions)"
  value       = module.apigw_kyb_agent.aws_api_gateway_stage_execution_arn
}

output "api_gateway_stage" {
  description = "Deployment stage of the API Gateway"
  value       = module.apigw_kyb_agent.aws_api_gateway_stage_name
}

output "api_invoke_policy_arn" {
  description = "IAM policy ARN for API invocation (attach to SSO permission sets)"
  value       = aws_iam_policy.api_invoke_policy.arn
}

output "agent_id" {
  description = "ID of the Bedrock KYB Agent"
  value       = awscc_bedrock_agent.kyb_agent.agent_id
}

output "agent_arn" {
  description = "ARN of the Bedrock KYB Agent"
  value       = awscc_bedrock_agent.kyb_agent.agent_arn
}

output "agent_alias_id" {
  description = "ID of the live agent alias"
  value       = awscc_bedrock_agent_alias.kyb_agent_live.agent_alias_id
}

output "agent_alias_arn" {
  description = "ARN of the live agent alias"
  value       = awscc_bedrock_agent_alias.kyb_agent_live.agent_alias_arn
}

output "agent_role_arn" {
  description = "ARN of the Bedrock Agent IAM role"
  value       = aws_iam_role.bedrock_agent_role.arn
}

output "check_sanctions_role_arn" {
  description = "ARN of the CheckSanctions Lambda IAM role"
  value       = aws_iam_role.check_sanctions_role.arn
}