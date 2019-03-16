#
# User: Diego Ojeda
#
module "user_diego_ojeda" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-tf/modules/iam-user?ref=v0.2"

    name = "diego.ojeda"
    force_destroy = true
    password_reset_required = true

    create_iam_user_login_profile = true
    create_iam_access_key = false
    upload_iam_user_ssh_key = false

    pgp_key = "${file("keys/diego.ojeda")}"
}

output "user_diego_ojeda_name" {
    description = "The user's name"
    value       = "${module.user_diego_ojeda.this_iam_user_name}"
}

# output "user_diego_ojeda_login_profile_encrypted_password" {
#     description = "The encrypted password, base64 encoded"
#     value       = "${module.user_diego_ojeda.this_iam_user_login_profile_encrypted_password}"
# }

#
# User: Marcos Pagnucco
#
module "user_marcos_pagnuco" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-tf/modules/iam-user?ref=v0.2"

    name = "marcos.pagnucco"
    force_destroy = true
    password_reset_required = true

    create_iam_user_login_profile = true
    create_iam_access_key = false
    upload_iam_user_ssh_key = false

    pgp_key = "${file("keys/marcos.pagnucco")}"
}

output "user_marcos_pagnuco_name" {
    description = "The user's name"
    value       = "${module.user_marcos_pagnuco.this_iam_user_name}"
}

# output "user_marcos_pagnuco_login_profile_encrypted_password" {
#     description = "The encrypted password, base64 encoded"
#     value       = "${module.user_marcos_pagnuco.this_iam_user_login_profile_encrypted_password}"
# }

#
# User: Exequiel Barrirero
#
module "user_exequiel_barrirero" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-tf/modules/iam-user?ref=v0.2"

    name = "exequiel.barrirero"
    force_destroy = true
    password_reset_required = true

    create_iam_user_login_profile = true
    create_iam_access_key = false
    upload_iam_user_ssh_key = false

    pgp_key = "${file("keys/exequiel.barrirero")}"
}

output "user_exequiel_barrirero_name" {
    description = "The user's name"
    value       = "${module.user_exequiel_barrirero.this_iam_user_name}"
}

# output "user_exequiel_barrirero_login_profile_encrypted_password" {
#     description = "The encrypted password, base64 encoded"
#     value       = "${module.user_exequiel_barrirero.this_iam_user_login_profile_encrypted_password}"
# }
