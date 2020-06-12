#
# Policies attached to Groups
#

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

#
# Policy: Assume Finops Role (Cross-Org Accounts)
#
resource "aws_iam_policy" "assume_finops_role" {
  name        = "assume_finops_role"
  description = "Allow assume FinOps role in member accounts"

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
                "arn:aws:iam::${var.shared_account_id}:role/FinOps",
                "arn:aws:iam::${var.appsdevstg_account_id}:role/FinOps",
                "arn:aws:iam::${var.appsprd_account_id}:role/FinOps"
            ]
        }
    ]
}
EOF
}
