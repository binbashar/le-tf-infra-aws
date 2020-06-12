#
# KMS aws_kms_key outputs
#
output "aws_kms_key_arn" {
  description = "Key ARN"
  value       = module.kms_key.key_arn
}

output "aws_kms_key_id" {
  description = "KMS Key ID"
  value       = module.kms_key.key_id
}

output "aws_kms_key_alias_arn" {
  description = "KMS Alias ARN"
  value       = module.kms_key.alias_arn
}

output "aws_kms_key_alias_name" {
  description = "KMS Alias name"
  value       = module.kms_key.alias_name
}

#
#
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
