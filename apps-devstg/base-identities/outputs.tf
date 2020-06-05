#
# users.tf sensitive data output (alphabetically ordered)
#
# Machine / Automation Users
#
output "user_auditor_ci_name" {
  description = "The user's name"
  value       = module.user_auditor_ci.this_iam_user_name
}

output "user_auditor_ci_iam_access_key_id" {
  description = "The aws aim access key"
  value       = module.user_auditor_ci.this_iam_access_key_id
  sensitive   = true
}

output "user_auditor_ci_iam_access_key_encrypted_secret" {
  description = "The encrypted secret key, base64 encoded"
  value       = module.user_auditor_ci.this_iam_access_key_encrypted_secret
  sensitive   = true
}
