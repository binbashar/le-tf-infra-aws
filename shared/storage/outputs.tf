output "gdrive_backup_bucket_arn" {
  description = "GDrive Backup Bucket ARN"
  value       = aws_s3_bucket.gdrive_backup.arn
}
