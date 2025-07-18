output "s3_bucket_data_raw_arn" {
  description = "The ARN of the raw S3 bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.s3_bucket_data_raw.s3_bucket_arn
}