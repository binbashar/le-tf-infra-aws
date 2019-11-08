#
# Roles
#

#
# Assumable Role Cross-Account: DevOps
#
module "iam_assumable_roles" {
  source = "git::git@github.com:binbashar/terraform-aws-iam-role-sts.git?ref=v0.0.2"

  trusted_role_arns = [
    "arn:aws:iam::${var.security_account_id}:root",
  ]

  role_name         = "DevOps"
  role_requires_mfa = false
  role_policy_arn   = "${aws_iam_policy.devops_access.arn}"
}

#
# Admin Role
#
resource "aws_iam_role" "admin_role" {
  name = "Admin"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": [
            "arn:aws:iam::${var.security_account_id}:root"
        ]

      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#
# Assumable Role Cross-Account: Auditor Role
#
resource "aws_iam_role" "auditor_role" {
  name = "Auditor"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": [
            "arn:aws:iam::${var.security_account_id}:root"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#
# Assumable Role Cross-Account: DeployMaster
#
module "iam_assumable_roles_deploy_master" {
  source = "git::git@github.com:binbashar/terraform-aws-iam-role-sts.git?ref=v0.0.2"

  trusted_role_arns = [
    "arn:aws:iam::${var.security_account_id}:root",
  ]

  role_name         = "DeployMaster"
  role_requires_mfa = false
  role_policy_arn   = "${aws_iam_policy.deploy_master_access.arn}"
}
