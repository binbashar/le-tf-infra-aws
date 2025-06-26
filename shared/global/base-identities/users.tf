module "user" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v5.9.2"
  for_each = var.users

  name                          = each.value.name
  force_destroy                 = each.value.force_destroy
  password_reset_required       = each.value.password_reset_required
  create_iam_user_login_profile = each.value.create_iam_user_login_profile
  create_iam_access_key         = each.value.create_iam_access_key
  upload_iam_user_ssh_key       = each.value.upload_iam_user_ssh_key
  pgp_key                      = file(each.value.pgp_key)
}
