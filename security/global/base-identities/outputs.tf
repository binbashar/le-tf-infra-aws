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

output "user_matias_rodriguez_name" {
  description = "The user's name"
  value       = module.user["matias.rodriguez"].iam_user_name
}

output "user_matias_rodriguez_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user["matias.rodriguez"].iam_user_login_profile_encrypted_password
  sensitive   = true
}

output "user_franco_gauchat_name" {
  description = "The user's name"
  value       = module.user["franco.gauchat"].iam_user_name
}

output "user_franco_gauchat_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.user["franco.gauchat"].iam_user_login_profile_encrypted_password
  sensitive   = true
}

#
# Machine / Automation Users
#
output "machine_users" {
  description = "All machine users: username, access_key_id, and access_key_secret for each."
  value = {
    for k, v in module.machine_user :
      k => {
        username          = v.iam_user_name
        access_key_id     = v.iam_access_key_id
        access_key_secret = v.iam_access_key_encrypted_secret
      }
  }
  sensitive = true
}
