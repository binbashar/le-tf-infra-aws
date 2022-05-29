#
# Create a role that will be assumed from specific users in Security account.
#
module "user_roles" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.7.0"

  for_each = toset(var.usernames)

  create_role             = true
  role_name               = "${var.prefix}-role-${each.key}"
  role_requires_mfa       = false
  trusted_role_arns       = ["arn:aws:iam::${var.security_account_id}:root"]
  custom_role_policy_arns = [aws_iam_policy.user_roles_policy[each.key].arn]
}

#
# The role will be attached t o a policy that enables access to a given S3 buclet.
#
resource "aws_iam_policy" "user_roles_policy" {
  for_each = toset(var.usernames)

  name        = "${var.prefix}-policy-${each.key}"
  path        = "/"
  description = "Customer File Shares"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
       "Action": [
         "kms:Decrypt",
         "kms:Encrypt",
         "kms:GenerateDataKey",
         "kms:ReEncryptTo",
         "kms:DescribeKey",
         "kms:ReEncryptFrom"
       ],
       "Resource": "${data.terraform_remote_state.keys.outputs.aws_kms_key_arn}"
    },
    {
      "Action": [
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "${module.user_buckets[each.key].s3_bucket_arn}"
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${module.user_buckets[each.key].s3_bucket_arn}/*"
    }
  ]
}
EOF
}
