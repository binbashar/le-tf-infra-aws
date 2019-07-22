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
<<<<<<< HEAD
=======

output "user_gonzalo_martinez_name" {

  description = "The user's name"
  value       = "${module.user_gonzalo_martinez.this_iam_user_name}"
}

output "user_gonzalo_martinez_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = "${module.user_gonzalo_martinez.this_iam_user_login_profile_encrypted_password}"
  sensitive   = true
}
>>>>>>> fe8f8422339b15f2f709d3964e6e17a704531153
