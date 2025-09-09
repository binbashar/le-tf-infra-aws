output "agent_id" {
  description = "The ID of the Bedrock agent"
  value       = module.bedrock_agent.bedrock_agent[0].agent_id
}

output "agent_arn" {
  description = "The ARN of the Bedrock agent"
  value       = module.bedrock_agent.bedrock_agent[0].agent_arn
}

output "agent_name" {
  description = "The name of the Bedrock agent"
  value       = local.agent_name
}

output "agent_version" {
  description = "The version of the Bedrock agent (DRAFT)"
  value       = "DRAFT"
}

output "documents_bucket_name" {
  description = "Name of the S3 bucket for documents"
  value       = aws_s3_bucket.documents.id
}

output "documents_bucket_arn" {
  description = "ARN of the S3 bucket for documents"
  value       = aws_s3_bucket.documents.arn
}

output "s3_read_lambda_arn" {
  description = "ARN of the S3 read Lambda function"
  value       = aws_lambda_function.s3_read.arn
}

output "s3_write_lambda_arn" {
  description = "ARN of the S3 write Lambda function"
  value       = aws_lambda_function.s3_write.arn
}

output "action_group_names" {
  description = "List of action group names created for the agent"
  value       = [local.s3_read_action_group, local.s3_write_action_group]
}

output "bedrock_agent_layer_arn" {
  description = "ARN of the Bedrock Agent utilities Lambda layer"
  value       = aws_lambda_layer_version.bedrock_agent_utils.arn
}

output "bedrock_agent_layer_version" {
  description = "Version of the Bedrock Agent utilities Lambda layer"
  value       = aws_lambda_layer_version.bedrock_agent_utils.version
}
