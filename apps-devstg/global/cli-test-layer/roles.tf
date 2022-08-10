#
# IAM Roles
#

#
# Assumable Role Cross-Account: Leverage Test
#
module "iam_assumable_role_leverage_test" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.7.0"

  trusted_role_arns = [
    "arn:aws:iam::${var.accounts.security.id}:root"
  ]

  create_role = true
  role_name   = "LeverageTest"
  role_path   = "/"

  #
  # MFA setup
  #
  role_requires_mfa = false
  custom_role_policy_arns = [
    aws_iam_policy.leverage_test.arn
  ]

  tags = local.tags
}
