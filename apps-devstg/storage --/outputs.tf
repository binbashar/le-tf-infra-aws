output "velero_bucket_arn" {
  description = "Velero Bucket ARN"
  value       = aws_s3_bucket.velero.arn
}