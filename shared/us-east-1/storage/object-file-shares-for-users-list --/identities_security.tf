#
# Create an IAM User in Security account but from here.
#
module "user_accounts" {
  providers = {
    aws = aws.security
  }

  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-user?ref=v4.24.1"

  for_each = toset(var.usernames)

  name                          = "${var.prefix}-user-${each.key}"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = true
  pgp_key                       = file("${path.root}/../../../../security/global/base-identities/keys/machine.s3.demo")
}

resource "aws_iam_user_policy" "bucket_user_assume_role_permissions" {
  provider = aws.security

  for_each = toset(var.usernames)

  name   = "${var.prefix}-policy-${each.key}"
  user   = module.user_accounts[each.key].iam_user_name
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
        "${module.user_roles[each.key].iam_role_arn}"
      ]
    }
  ]
}
EOF
}
