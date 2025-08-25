#
# AWS IAM Users
#
module "user" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v5.60.0"

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
