#=============================#
# MWAA Outputs                #
#=============================#
output "mwaa_arn" {
  description = "ARN of the MWAA Environment"
  value       = module.mwaa.mwaa_arn
}

output "mwaa_status" {
  description = "Status of the MWAA Environment"
  value       = module.mwaa.mwaa_status
}

output "mwaa_webserver_url" {
  description = "Webserver URL of the MWAA Environment"
  value       = module.mwaa.mwaa_webserver_url
}

output "mwaa_role_arn" {
  description = "IAM Role ARN of the MWAA Environment"
  value       = module.mwaa.mwaa_role_arn
}

output "mwaa_role_name" {
  description = "IAM Role Name of the MWAA Environment"
  value       = module.mwaa.mwaa_role_name
}

output "mwaa_security_group_id" {
  description = "Security Group ID of the MWAA Environment"
  value       = module.mwaa.mwaa_security_group_id
}

output "s3_bucket_name" {
  description = "S3 Bucket Name for MWAA"
  value       = module.mwaa.aws_s3_bucket_name
}
