#
# users.tf sensitive data output (alphabetically ordered)
#
# Machine / Automation Users
#
output "user_auditor_ci_name" {
  description = "The user's name"
  value       = module.user_auditor_ci.iam_user_name
}

output "user_auditor_ci_iam_access_key_id" {
  description = "The aws aim access key"
  value       = module.user_auditor_ci.iam_access_key_id
  sensitive   = true
}

output "user_auditor_ci_iam_access_key_encrypted_secret" {
  description = "The encrypted secret key, base64 encoded"
  value       = module.user_auditor_ci.iam_access_key_encrypted_secret
  sensitive   = true
}

output "user_backup_se_name" {
  description = "The user's name"
  value       = module.user_backup_s3.iam_user_name
}

output "user_backup_s3_iam_access_key_id" {
  description = "The aws aim access key"
  value       = module.user_backup_s3.iam_access_key_id
  sensitive   = true
}

output "user_backup_s3_iam_access_key_encrypted_secret" {
  description = "The encrypted secret key, base64 encoded"
  value       = module.user_backup_s3.iam_access_key_encrypted_secret
  sensitive   = true
}
