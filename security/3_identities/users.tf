#==========================#
# User: Diego Ojeda        #
#==========================#
module "user_diego_ojeda" {
  source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-tf/modules/iam-user?ref=v0.6"

  name                    = "diego.ojeda"
  force_destroy           = true
  password_reset_required = true

  create_iam_user_login_profile = true
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = "${file("keys/diego.ojeda")}"
}

#==========================#
# User: Marcos Pagnucco    #
#==========================#
module "user_marcos_pagnuco" {
  source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-tf/modules/iam-user?ref=v0.6"

  name                    = "marcos.pagnucco"
  force_destroy           = true
  password_reset_required = true

  create_iam_user_login_profile = true
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = "${file("keys/marcos.pagnucco")}"
}

#==========================#
# User: Exequiel Barrirero #
#==========================#
module "user_exequiel_barrirero" {
  source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-tf/modules/iam-user?ref=v0.6"

  name                    = "exequiel.barrirero"
  force_destroy           = true
  password_reset_required = true

  create_iam_user_login_profile = true
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = "${file("keys/exequiel.barrirero")}"
}
