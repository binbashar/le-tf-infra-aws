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

# Planned outputs to be added during remaining implementation:
# - BDA project name and ARN (T-003: Bedrock Data Automation Setup)
# - Lambda function names and ARNs (T-005: Lambda Functions Implementation)
# - EventBridge rule names and ARNs (T-004: EventBridge Rules Configuration)
# - Bedrock Agent ID and ARN (T-009: Bedrock Agent Configuration)
# - IAM role ARNs (T-011: IAM Permissions Setup)