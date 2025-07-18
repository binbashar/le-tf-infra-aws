output "kinesis_stream_arn" {
  description = "The ARN of the Kinesis stream for DynamoDB to S3 (Raw Bucket)"
  value       = module.kinesis_stream_datalake.stream_arn
}

output "kinesis_firehose_role_arn" {
  description = "The ARN of the IAM role created for Kinesis Firehose Stream"
  value       = module.kinesis_firehose_datalake.kinesis_firehose_role_arn
}