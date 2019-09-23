//
//users.tf sensitive data output
//
output "user_diego_ojeda_name" {
  description = "The user's name"
  value       = "${module.user_diego_ojeda.this_iam_user_name}"
}

output "user_diego_ojeda_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = "${module.user_diego_ojeda.this_iam_user_login_profile_encrypted_password}"
  sensitive   = true
}

output "user_marcos_pagnuco_name" {
  description = "The user's name"
  value       = "${module.user_marcos_pagnuco.this_iam_user_name}"
}

output "user_marcos_pagnuco_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = "${module.user_marcos_pagnuco.this_iam_user_login_profile_encrypted_password}"
  sensitive   = true
}

output "user_exequiel_barrirero_name" {
  description = "The user's name"
  value       = "${module.user_exequiel_barrirero.this_iam_user_name}"
}

output "user_exequiel_barrirero_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = "${module.user_exequiel_barrirero.this_iam_user_login_profile_encrypted_password}"
  sensitive   = true
}

output "user_gonzalo_martinez_name" {

  description = "The user's name"
  value       = "${module.user_gonzalo_martinez.this_iam_user_name}"
}

output "user_gonzalo_martinez_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = "${module.user_gonzalo_martinez.this_iam_user_login_profile_encrypted_password}"
  sensitive   = true
}

output "user_circle_ci_name" {
  description = "The user's name"
  value       = "${module.user_circle_ci.this_iam_user_name}"
}

output "user_circle_ci_iam_access_key_id" {
  description = "The aws aim access key"
  value       = "${module.user_circle_ci.this_iam_access_key_id}"
  sensitive   = true
}

output "user_circle_ci_iam_access_key_encrypted_secret" {
  description = "The encrypted secret key, base64 encoded"
  value       = "${module.user_circle_ci.this_iam_access_key_encrypted_secret}"
  sensitive   = true
}