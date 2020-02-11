#
# Policies attached to Groups
#

#
# Policy: Standard AWS Console User Security Account
#
resource "aws_iam_policy" "standard_console_user" {
  name        = "standard_console_user"
  description = "Base policy for AWS console users"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetAccountPasswordPolicy",
                "iam:ListAccountAliases",
                "iam:ListUsers",
                "iam:GetLoginProfile",
                "iam:GetAccountSummary"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:*AccessKey*",
                "iam:*SigningCertificate*",
                "iam:GetUser",
                "iam:ChangePassword",
                "iam:*ServiceSpecificCredential*",
                "iam:UpdateLoginProfile",
                "iam:*MFA*"
            ],
            "Resource": [
                "arn:aws:iam::*:user/$${aws:username}",
                "arn:aws:iam::*:mfa/$${aws:username}"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume DevOps Role (Cross-Org Accounts)
#
resource "aws_iam_policy" "assume_devops_role" {
  name        = "assume_devops_role"
  description = "Allow assume DevOps role in member accounts"

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
                "arn:aws:iam::${var.shared_account_id}:role/DevOps",
                "arn:aws:iam::${var.security_account_id}:role/DevOps",
                "arn:aws:iam::${var.appsdevstg_account_id}:role/DevOps",
                "arn:aws:iam::${var.appsprd_account_id}:role/DevOps"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume Admin Role (Cross-Org Accounts)
#
resource "aws_iam_policy" "assume_admin_role" {
  name        = "assume_admin_role"
  description = "Allow assume Admin role in member accounts"

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
                "arn:aws:iam::${var.shared_account_id}:role/Admin",
                "arn:aws:iam::${var.security_account_id}:role/Admin",
                "arn:aws:iam::${var.appsdevstg_account_id}:role/Admin",
                "arn:aws:iam::${var.appsprd_account_id}:role/Admin"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume DeployMaster Role (Cross-Org Accounts)
#
resource "aws_iam_policy" "assume_deploymaster_role" {
  name        = "assume_deploymaster_role"
  description = "Allow assume DeployMaster role in member accounts"

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
                "arn:aws:iam::${var.shared_account_id}:role/DeployMaster",
                "arn:aws:iam::${var.appsdevstg_account_id}:role/DeployMaster",
                "arn:aws:iam::${var.appsprd_account_id}:role/DeployMaster"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume Auditor Role (Cross-Org Accounts)
#
resource "aws_iam_policy" "assume_auditor_role" {
  name        = "assume_auditor_role"
  description = "Allow assume Auditor role in member accounts"

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
                "arn:aws:iam::${var.shared_account_id}:role/Auditor",
                "arn:aws:iam::${var.security_account_id}:role/Auditor",
                "arn:aws:iam::${var.appsdevstg_account_id}:role/Auditor",
                "arn:aws:iam::${var.appsprd_account_id}:role/Auditor"
            ]
        }
    ]
}
EOF
}
