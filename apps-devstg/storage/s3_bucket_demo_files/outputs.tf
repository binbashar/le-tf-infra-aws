#
# Bucket | Demo files
#
output "s3_bucket_demo_files_id" {
  description = "The name of the bucket."
  value       = module.s3_bucket_demo_files.this_s3_bucket_id
}

output "s3_bucket_demo_files_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.s3_bucket_demo_files.this_s3_bucket_arn
}

output "s3_bucket_demo_files_bucket_domain_name" {
  description = "The bucket domain name. Will be of format bucketname.s3.amazonaws.com."
  value       = module.s3_bucket_demo_files.this_s3_bucket_bucket_domain_name
}

output "s3_bucket_demo_files_region" {
  description = "The AWS region this bucket resides in."
  value       = module.s3_bucket_demo_files.this_s3_bucket_region
}

output "s3_bucket_demo_files_log_id" {
  description = "The name of the bucket."
  value       = module.log_bucket_demo_files.this_s3_bucket_id
}

#
# Bucket | Demo files logs
#
output "s3_bucket_demo_files_log_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.log_bucket_demo_files.this_s3_bucket_arn
}

output "s3_bucket_demo_files_bucket_log_domain_name" {
  description = "The bucket domain name. Will be of format bucketname.s3.amazonaws.com."
  value       = module.log_bucket_demo_files.this_s3_bucket_bucket_domain_name
}

output "s3_bucket_demo_files_log_region" {
  description = "The AWS region this bucket resides in."
  value       = module.log_bucket_demo_files.this_s3_bucket_region
}

#
# Bucket | Demo files replica
#
output "s3_bucket_demo_files_replica_id" {
  description = "The name of the bucket."
  value       = module.s3_bucket_demo_files_replica.this_s3_bucket_id
}

output "s3_bucket_demo_files_replica_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.s3_bucket_demo_files_replica.this_s3_bucket_arn
}

output "s3_bucket_demo_files_bucket_replica_domain_name" {
  description = "The bucket domain name. Will be of format bucketname.s3.amazonaws.com."
  value       = module.s3_bucket_demo_files_replica.this_s3_bucket_bucket_domain_name
}

output "s3_bucket_demo_files_replica_region" {
  description = "The AWS region this bucket resides in."
  value       = module.s3_bucket_demo_files_replica.this_s3_bucket_region
}
