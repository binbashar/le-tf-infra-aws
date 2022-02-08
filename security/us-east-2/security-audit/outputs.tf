#
# CloudTrail replication bucket
#
output "cloudtrail_replication_bucket_arn" {
  description = "Bucket ARN"
  value       = var.enable_cloudtrail_bucket_replication ? aws_s3_bucket.cloudtrail_s3_bucket-dr[0].arn : null
}

output "cloudtrail_replication_bucket_domain_name" {
  description = "FQDN of bucket"
  value       = var.enable_cloudtrail_bucket_replication ? aws_s3_bucket.cloudtrail_s3_bucket-dr[0].bucket_domain_name : null
}

output "cloudtrail_replication_bucket_id" {
  description = "Bucket ID"
  value       = var.enable_cloudtrail_bucket_replication ? aws_s3_bucket.cloudtrail_s3_bucket-dr[0].id : null
}

#
# Config replication bucket
#
output "config_replication_bucket_arn" {
  description = "Bucket ARN"
  value       = var.enable_config_bucket_replication ? aws_s3_bucket.config_s3_bucket-dr[0].arn : null
}

output "config_replication_bucket_domain_name" {
  description = "FQDN of bucket"
  value       = var.enable_config_bucket_replication ? aws_s3_bucket.config_s3_bucket-dr[0].bucket_domain_name : null
}

output "config_replication_bucket_id" {
  description = "Bucket ID"
  value       = var.enable_config_bucket_replication ? aws_s3_bucket.config_s3_bucket-dr[0].id : null
}
