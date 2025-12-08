#
# CloudTrail Bucket
#
output "bucket_arn" {
  description = "Bucket ARN"
  value       = module.cloudtrail_s3_bucket.bucket_arn
}

output "bucket_domain_name" {
  description = "FQDN of bucket"
  value       = module.cloudtrail_s3_bucket.bucket_domain_name
}

output "bucket_id" {
  description = "Bucket ID"
  value       = module.cloudtrail_s3_bucket.bucket_id
}
