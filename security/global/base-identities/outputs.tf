#
# users.tf sensitive data output (alphabetically ordered)
#
output "user_angelo_fenoglio_name" {
  description = "The user's name"
  value       = module.user_angelo_fenoglio.iam_user_name
}

/*output "user_angelo_fenoglio_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user_angelo_fenoglio.iam_user_login_profile_encrypted_password
  sensitive   = true
}*/

output "user_diego_ojeda_name" {
  description = "The user's name"
  value       = module.user_diego_ojeda.iam_user_name
}

/*output "user_diego_ojeda_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user_diego_ojeda.iam_user_login_profile_encrypted_password
  sensitive   = true
}*/

output "user_exequiel_barrirero_name" {
  description = "The user's name"
  value       = module.user_exequiel_barrirero.iam_user_name
}

/*output "user_exequiel_barrirero_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user_exequiel_barrirero.iam_user_login_profile_encrypted_password
  sensitive   = true
}*/

output "user_luis_gallardo_name" {
  description = "The user's name"
  value       = module.user_luis_gallardo.iam_user_name
}

/*output "user_luis_gallardo_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user_luis_gallardo.iam_user_login_profile_encrypted_password
  sensitive   = true
}*/

output "user_marcelo_beresvil_name" {
  description = "The user's name"
  value       = module.user_marcelo_beresvil.iam_user_name
}

/*output "user_marcelo_beresvil_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user_marcelo_beresvil.iam_user_login_profile_encrypted_password
  sensitive   = true
}*/

output "user_marcos_pagnuco_name" {
  description = "The user's name"
  value       = module.user_marcos_pagnuco.iam_user_name
}

/*output "user_marcos_pagnuco_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user_marcos_pagnuco.iam_user_login_profile_encrypted_password
  sensitive   = true
}*/

#
# Machine / Automation Users
#
output "user_circle_ci_name" {
  description = "The user's name"
  value       = module.user_circle_ci.iam_user_name
}

/*output "user_circle_ci_iam_access_key_id" {
  description = "The aws aim access key"
  value       = module.user_circle_ci.iam_access_key_id
  sensitive   = true
}

output "user_circle_ci_iam_access_key_encrypted_secret" {
  description = "The encrypted secret key, base64 encoded"
  value       = module.user_circle_ci.iam_access_key_encrypted_secret
  sensitive   = true
}*/

output "user_github_actions_name" {
  description = "The user's name"
  value       = module.user_github_actions.iam_user_name
}

output "user_s3_demo_name" {
  description = "The user's name"
  value       = module.user_s3_demo.iam_user_name
}

/*
output "user_s3_demo_iam_access_key_id" {
  description = "The aws aim access key"
  value       = module.user_s3_demo.iam_access_key_id
  sensitive   = false
}

output "user_s3_demo_iam_access_key_encrypted_secret" {
  description = "The encrypted secret key, base64 encoded"
  value       = module.user_s3_demo.iam_access_key_encrypted_secret
  sensitive   = false
}
*/

