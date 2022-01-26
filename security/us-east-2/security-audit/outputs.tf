#
# CloudTrail replication bucket
#
output "bucket_arn" {
  description = "Bucket ARN"
  value       = aws_s3_bucket.cloudtrail_s3_bucket-dr.arn
}

output "bucket_domain_name" {
  description = "FQDN of bucket"
  value       = aws_s3_bucket.cloudtrail_s3_bucket-dr.bucket_domain_name
}

output "bucket_id" {
  description = "Bucket ID"
  value       = aws_s3_bucket.cloudtrail_s3_bucket-dr.id
}
