#
# S3 Bucket for alb logs
#
output "s3_bucket_alb_logs_id" {
  description = "The name of the bucket."
  value       = module.s3_bucket_alb_logs.s3_bucket_id
}

output "s3_bucket_alb_logs_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.s3_bucket_alb_logs.s3_bucket_arn
}

output "s3_bucket_alb_logs_domain_name" {
  description = "The bucket domain name. Will be of format bucketname.s3.amazonaws.com."
  value       = module.s3_bucket_alb_logs.s3_bucket_bucket_domain_name
}

output "s3_bucket_alb_logs_region" {
  description = "The AWS region this bucket resides in."
  value       = module.s3_bucket_alb_logs.s3_bucket_region
}

output "s3_bucket_alb_logs_log_id" {
  description = "The name of the bucket."
  value       = module.s3_bucket_alb_logs.s3_bucket_id
}
