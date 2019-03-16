#
# Assumable Role: DevOps
#
module "iam_assumable_roles" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-bb/assumable-role?ref=v0.2"

    trusted_role_arns = [
        "arn:aws:iam::${var.security_account_id}:root"
    ]

    role_name = "DevOps"
    role_requires_mfa = false
    role_policy_arn = "${aws_iam_policy.devops_access.arn}"
}

#
# Policy: DevOps Access
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
                "iam:*",
                "kms:*",
                "lambda:*",
                "logs:*",
                "rds:*",
                "route53:*",
                "route53domains:*",
                "s3:*",
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
# Assumable Role: Poweruser
#
module "iam_assumable_roles_poweruser" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-bb/assumable-role?ref=v0.2"

    trusted_role_arns = [
        "arn:aws:iam::${var.security_account_id}:root"
    ]

    role_name = "Poweruser"
    role_requires_mfa = false
    role_policy_arn = "${aws_iam_policy.poweruser_access.arn}"
}

#
# Policy: Poweruser Access
#
resource "aws_iam_policy" "poweruser_access" {
    name        = "poweruser_access"
    description = "Services enabled for Poweruser role"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:DescribeRepositories",
                "ssm:DescribeParameters",
                "kms:ListAliases"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeImages",
                "ecr:ListImages",
                "ecr:BatchGetImage"
            ],
            "Resource": [
                "arn:aws:ecr:${var.region}:${var.shared_account_id}:repository/nativeweb-backend",
                "arn:aws:ecr:${var.region}:${var.shared_account_id}:repository/nativeweb-backend/*",
                "arn:aws:ecr:${var.region}:${var.shared_account_id}:repository/nativeweb-spa",
                "arn:aws:ecr:${var.region}:${var.shared_account_id}:repository/nativeweb-spa/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DeleteParameter",
                "ssm:DeleteParameters",
                "ssm:GetParameter",
                "ssm:GetParameterHistory",
                "ssm:GetParameters",
                "ssm:GetParametersByPath",
                "ssm:PutParameter",
                "ssm:ListTagsForResource"
            ],
            "Resource": [
                "arn:aws:ssm:${var.region}:${var.shared_account_id}:parameter/nwbe/dev/*",
                "arn:aws:ssm:${var.region}:${var.shared_account_id}:parameter/nwbe/stg/*",
                "arn:aws:ssm:${var.region}:${var.shared_account_id}:parameter/nwbe/prd/*"
            ]
        }
    ]
}
EOF
}

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

resource "aws_iam_role_policy_attachment" "auditors_have_read_only_access" {
    role       = "${aws_iam_role.auditor_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "auditors_have_security_audit_access" {
    role       = "${aws_iam_role.auditor_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

#
# Assumable Role: BI
#
module "iam_assumable_roles_bi" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/iam-bb/assumable-role?ref=v0.2"

    trusted_role_arns = [
        "arn:aws:iam::${var.security_account_id}:root"
    ]

    role_name = "BI"
    role_requires_mfa = false
    role_policy_arn = "${aws_iam_policy.bi_access.arn}"
}

#
# Policy: BI Access
#
resource "aws_iam_policy" "bi_access" {
    name        = "bi_access"
    description = "Services enabled for BI role"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:DescribeRepositories",
                "ssm:DescribeParameters",
                "kms:ListAliases"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeImages",
                "ecr:ListImages",
                "ecr:BatchGetImage"
            ],
            "Resource": [
                "arn:aws:ecr:${var.region}:${var.shared_account_id}:repository/nw-bi",
                "arn:aws:ecr:${var.region}:${var.shared_account_id}:repository/nw-bi/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DeleteParameter",
                "ssm:DeleteParameters",
                "ssm:GetParameter",
                "ssm:GetParameterHistory",
                "ssm:GetParameters",
                "ssm:GetParametersByPath",
                "ssm:PutParameter",
                "ssm:ListTagsForResource"
            ],
            "Resource": [
                "arn:aws:ssm:${var.region}:${var.shared_account_id}:parameter/nwbi/dev/*",
                "arn:aws:ssm:${var.region}:${var.shared_account_id}:parameter/nwbi/prd/*"
            ]
        }
    ]
}
EOF
}