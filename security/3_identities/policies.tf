#
# Policy: Standard AWS Console User
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
                "iam:GetAccountSummary",
                "iam:GetLoginProfile",
                "iam:ListAccountAliases",
                "iam:ListUsers",
                "iam:GetAccountPasswordPolicy"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:*AccessKey*",
                "iam:ChangePassword",
                "iam:GetUser",
                "iam:*ServiceSpecificCredential*",
                "iam:*SigningCertificate*"
            ],
            "Resource": ["arn:aws:iam::*:user/${var.aws_username}"]
        }
    ]
}
EOF
}

#
# Policy: Assume Admin Role
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
                "arn:aws:iam::${var.dev_account_id}:role/Admin"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume DevOps Role
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
                "arn:aws:iam::${var.dev_account_id}:role/DevOps"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume DeployMaster Role
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
                "arn:aws:iam::${var.dev_account_id}:role/DeployMaster"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume Auditor Role
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
                "arn:aws:iam::${var.dev_account_id}:role/Auditor"
            ]
        }
    ]
}
EOF
}
