#
# Account Resources
#
module "aws_iam_account_config" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-account?ref=v4.1.0"

  // If IAM account alias was previously set (either via AWS console or during the creation of an account from AWS
  // Organizations) you will see this error:
  // * aws_iam_account_alias.this: Error creating account alias with name my-account-alias
  // please check https://github.com/binbashar/terraform-aws-iam/tree/master/modules/iam-account to solve it
  account_alias = "${var.project_long}-${var.environment}"

  # account password policy
  create_account_password_policy = true
  max_password_age               = 60
  minimum_password_length        = 30
  require_numbers                = true
  require_lowercase_characters   = true
  require_symbols                = true
  require_uppercase_characters   = true
  password_reuse_prevention      = 12
  allow_users_to_change_password = true
}

data "aws_caller_identity" "current" {}
