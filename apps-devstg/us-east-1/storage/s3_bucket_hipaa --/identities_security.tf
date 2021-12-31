#
# Create an IAM User in Security account but from here.
#
module "customers_user_accounts" {
  providers = {
    aws = aws.security
  }

  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.7.0"

  for_each = toset(var.customers)

  name                          = "${var.prefix}-user-${each.key}"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = true
  pgp_key                       = file("keys/machine.s3.demo")
}

resource "aws_iam_user_policy" "customers_assume_role_permissions" {
  provider = aws.security

  for_each = toset(var.customers)

  name   = "${var.prefix}-policy-${each.key}"
  user   = module.customers_user_accounts[each.key].iam_user_name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "${module.customers_roles[each.key].iam_role_arn}"
      ]
    }
  ]
}
EOF
}
