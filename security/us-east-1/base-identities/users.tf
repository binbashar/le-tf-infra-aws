#
# AWS IAM Users (alphabetically ordered)
#

#==========================#
# User: Angelo Fenoglio    #
#==========================#
module "user_angelo_fenoglio" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.1.0"

  name                    = "angelo.fenoglio"
  force_destroy           = true
  password_reset_required = true
  password_length         = 30

  create_iam_user_login_profile = true
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/angelo.fenoglio")
}

#==========================#
# User: Diego Ojeda        #
#==========================#
module "user_diego_ojeda" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.1.0"

  name                    = "diego.ojeda"
  force_destroy           = true
  password_reset_required = true
  password_length         = 30

  create_iam_user_login_profile = true
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/diego.ojeda")
}

#==========================#
# User: Exequiel Barrirero #
#==========================#
module "user_exequiel_barrirero" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.1.0"

  name                    = "exequiel.barrirero"
  force_destroy           = true
  password_reset_required = true
  password_length         = 30

  create_iam_user_login_profile = true
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/exequiel.barrirero")
}

#==========================#
# User: Marcelo Beresvil   #
#==========================#
module "user_marcelo_beresvil" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.1.0"

  name                    = "marcelo.beresvil"
  force_destroy           = true
  password_reset_required = true
  password_length         = 30

  create_iam_user_login_profile = true
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/marcelo.beresvil")
}

#==========================#
# User: Luis Gallardo      #
#==========================#
module "user_luis_gallardo" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.1.0"

  name                    = "luis.gallardo"
  force_destroy           = true
  password_reset_required = true
  password_length         = 30

  create_iam_user_login_profile = true
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/luis.gallardo")
}

#==========================#
# User: Marcos Pagnucco    #
#==========================#
module "user_marcos_pagnuco" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.1.0"

  name                    = "marcos.pagnucco"
  force_destroy           = true
  password_reset_required = true
  password_length         = 30

  create_iam_user_login_profile = true
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/marcos.pagnucco")
}

#
# Machine / Automation Users
#
#==========================#
# User: CircleCI           #
#==========================#
module "user_circle_ci" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.1.0"

  name                    = "circle.ci"
  force_destroy           = true
  password_reset_required = true

  create_iam_user_login_profile = false
  create_iam_access_key         = true
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/machine.circle.ci")
}

#==========================#
# User: CircleCI           #
#==========================#
module "user_github_actions" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.1.0"

  name                    = "github.actions"
  force_destroy           = true
  password_reset_required = true

  create_iam_user_login_profile = false
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/machine.github.actions")
}

#==========================#
# User: S3 Demo            #
#==========================#
module "user_s3_demo" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.1.0"

  name                    = "s3.demo"
  force_destroy           = true
  password_reset_required = true

  create_iam_user_login_profile = false
  create_iam_access_key         = true
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/machine.s3.demo")
}
