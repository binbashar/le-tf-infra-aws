#
# Roles
#

#
# Assumable Role: DevOps
#
module "iam_assumable_roles" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-bb/assumable-role?ref=v0.5"

    trusted_role_arns = [
        "arn:aws:iam::${var.security_account_id}:root"
    ]

    role_name = "DevOps"
    role_requires_mfa = false
    role_policy_arn = "${aws_iam_policy.devops_access.arn}"
}

#
# User Managed Policy: DevOps Access
#
resource "aws_iam_policy" "devops_access" {
    name        = "devops_access"
    description = "Services enabled for DevOps role"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "acm:*",
                "autoscaling:*",
                "application-autoscaling:*",
                "aws-portal:*",
                "backup:*",
                "backup-storage:*",
                "ce:*",
                "cloudformation:*",
                "cloudfront:*",
                "cloudtrail:*",
                "cloudwatch:*",
                "config:*",
                "dlm:*",
                "dynamodb:*",
                "ec2:*",
                "ecr:*",
                "ecs:*",
                "elasticloadbalancing:*",
                "events:*",
                "health:*",
                "iam:*",
                "kms:*",
                "lambda:*",
                "logs:*",
                "redshift:*",
                "rds:*",
                "route53:*",
                "route53domains:*",
                "s3:*",
                "shield:*",
                "sns:*",
                "sqs:*",
                "ssm:*",
                "vpc:*",
                "waf:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

#
# Admin Role
#
resource "aws_iam_role" "admin_role" {
    name                 = "Admin"
    path                 = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": [
            "arn:aws:iam::${var.shared_account_id}:root"
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
# AWS Managed Policy: Admin Access
#
resource "aws_iam_role_policy_attachment" "admins_have_read_only_access" {
    role       = "${aws_iam_role.admin_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#
# Auditor Role
#
resource "aws_iam_role" "auditor_role" {
    name                 = "Auditor"
    path                 = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": [
            "arn:aws:iam::${var.security_account_id}:root",
            "arn:aws:iam::${var.shared_account_id}:root"
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
# AWS Managed Policies: Auditor Access
#
resource "aws_iam_role_policy_attachment" "auditors_have_read_only_access" {
    role       = "${aws_iam_role.auditor_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "auditors_have_security_audit_access" {
    role       = "${aws_iam_role.auditor_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

#
# Assumable Role: DeployMaster
#
module "iam_assumable_roles_deploy_master" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-bb/assumable-role?ref=v0.5"

    trusted_role_arns = [
        "arn:aws:iam::${var.shared_account_id}:root"
    ]

    role_name = "DeployMaster"
    role_requires_mfa = false
    role_policy_arn = "${aws_iam_policy.deploy_master_access.arn}"
}
#
# Policy: DeployMaster
#
resource "aws_iam_policy" "deploy_master_access" {
    name        = "deploy_master_access"
    description = "Services enabled for DeployMaster role"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sqs:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}
