#
# users.tf sensitive data output (alphabetically ordered)
#
output "user_angelo_fenoglio_name" {
  description = "The user's name"
  value       = module.user["angelo.fenoglio"].iam_user_name
}

output "user_angelo_fenoglio_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user["angelo.fenoglio"].iam_user_login_profile_encrypted_password
  sensitive   = true
}

output "user_diego_ojeda_name" {
  description = "The user's name"
  value       = module.user["diego.ojeda"].iam_user_name
}

output "user_diego_ojeda_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user["diego.ojeda"].iam_user_login_profile_encrypted_password
  sensitive   = true
}

output "user_exequiel_barrirero_name" {
  description = "The user's name"
  value       = module.user["exequiel.barrirero"].iam_user_name
}

output "user_exequiel_barrirero_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user["exequiel.barrirero"].iam_user_login_profile_encrypted_password
  sensitive   = true
}

output "user_jose_peinado_name" {
  description = "The user's name"
  value       = module.user["jose.peinado"].iam_user_name
}

output "user_jose_peinado_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user["jose.peinado"].iam_user_login_profile_encrypted_password
  sensitive   = true
}

output "user_luis_gallardo_name" {
  description = "The user's name"
  value       = module.user["luis.gallardo"].iam_user_name
}

output "user_luis_gallardo_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user["luis.gallardo"].iam_user_login_profile_encrypted_password
  sensitive   = true
}

output "user_marcelo_beresvil_name" {
  description = "The user's name"
  value       = module.user["marcelo.beresvil"].iam_user_name
}

output "user_marcelo_beresvil_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user["marcelo.beresvil"].iam_user_login_profile_encrypted_password
  sensitive   = true
}

output "user_marcos_pagnuco_name" {
  description = "The user's name"
  value       = module.user["marcos.pagnucco"].iam_user_name
}

output "user_marcos_pagnuco_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user["marcos.pagnucco"].iam_user_login_profile_encrypted_password
  sensitive   = true
}

#
# Machine / Automation Users
#
output "user_circle_ci_name" {
  description = "The user's name"
  value       = module.machine_user["machine.circle.ci"].iam_user_name
}

output "user_circle_ci_iam_access_key_id" {
  description = "The aws aim access key"
  value       = module.machine_user["machine.circle.ci"].iam_access_key_id
  sensitive   = true
}

output "user_circle_ci_iam_access_key_encrypted_secret" {
  description = "The encrypted secret key, base64 encoded"
  value       = module.machine_user["machine.circle.ci"].iam_access_key_encrypted_secret
  sensitive   = true
}

output "user_github_actions_name" {
  description = "The user's name"
  value       = module.machine_user["machine.github.actions"].iam_user_name
}

output "user_s3_demo_name" {
  description = "The user's name"
  value       = module.machine_user["machine.s3.demo"].iam_user_name
}

output "user_s3_demo_iam_access_key_id" {
  description = "The aws aim access key"
  value       = module.machine_user["machine.s3.demo"].iam_access_key_id
  sensitive   = true
}

output "user_s3_demo_iam_access_key_encrypted_secret" {
  description = "The encrypted secret key, base64 encoded"
  value       = module.machine_user["machine.s3.demo"].iam_access_key_encrypted_secret
  sensitive   = true
}



