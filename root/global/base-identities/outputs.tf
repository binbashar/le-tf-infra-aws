#
# users.tf sensitive data output (alphabetically ordered)
#
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
