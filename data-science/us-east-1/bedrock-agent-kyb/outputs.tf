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