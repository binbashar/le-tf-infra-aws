output "agent_runtime_id" {
  description = "ID of the AgentCore runtime"
  value       = awscc_bedrockagentcore_runtime.this.agent_runtime_id
}

output "agent_runtime_arn" {
  description = "ARN of the AgentCore runtime"
  value       = awscc_bedrockagentcore_runtime.this.agent_runtime_arn
}

output "agent_runtime_endpoint_id" {
  description = "ID of the AgentCore runtime endpoint"
  value       = awscc_bedrockagentcore_runtime_endpoint.this.runtime_endpoint_id
}

output "agent_runtime_endpoint_arn" {
  description = "ARN of the AgentCore runtime endpoint"
  value       = awscc_bedrockagentcore_runtime_endpoint.this.agent_runtime_endpoint_arn
}

output "runtime_role_arn" {
  description = "ARN of the IAM role used by the AgentCore runtime"
  value       = aws_iam_role.runtime.arn
}

output "runtime_role_name" {
  description = "Name of the IAM role used by the AgentCore runtime"
  value       = aws_iam_role.runtime.name
}

output "code_bucket_name" {
  description = "Name of the S3 bucket for agent code artifacts"
  value       = aws_s3_bucket.code.id
}

output "code_bucket_arn" {
  description = "ARN of the S3 bucket for agent code artifacts"
  value       = aws_s3_bucket.code.arn
}
