#
# AWS IAM Users
#
module "user" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v5.9.2"

  for_each = toset(local.users)

  name                    = each.key
  force_destroy           = true
  password_reset_required = true
  password_length         = 30

  create_iam_user_login_profile = true
  create_iam_access_key         = false
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/${each.key}")
}

module "machine_user" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v5.9.2"

  for_each = toset(local.machine_users)

  name                    = each.key
  force_destroy           = true
  password_reset_required = true

  create_iam_user_login_profile = false
  create_iam_access_key         = true
  upload_iam_user_ssh_key       = false

  #
  # TODO These machine users are managed by us, the DevOps/Infra team. For
  # these we don't really need to create separate GPG keys per user because we
  # will be ones decrypting the encrypted secret access key. So, a single key
  # should suffice and simplify the process.
  #
  pgp_key = file("keys/${each.key}")
}
