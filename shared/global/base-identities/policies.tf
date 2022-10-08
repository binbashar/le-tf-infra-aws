#
# Policies attached to Roles
#

#
# Customer Managed Policy: DevOps Access
#
resource "aws_iam_policy" "devops_access" {
  name        = "devops_access"
  description = "Services enabled for DevOps role"

  #
  # IMPORTANT: Multiple condition keys in the same statement are not supported for some ec2 and rds actions.
  #
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "MultiServiceFullAccessCustom",
            "Effect": "Allow",
            "Action": [
                "acm:*",
                "athena:*",
                "autoscaling:*",
                "appconfig:*",
                "application-autoscaling:*",
                "apprunner:*",
                "apigateway:*",
                "aws-portal:*",
                "aws-marketplace:*",
                "backup:*",
                "backup-storage:*",
                "ce:*",
                "cloudformation:*",
                "cloudfront:*",
                "cloudtrail:*",
                "cloudwatch:*",
                "config:*",
                "compute-optimizer:*",
                "datasync:*",
                "dlm:*",
                "dynamodb:*",
                "ec2:*",
                "ecr:*",
                "ecr-public:*",
                "ecs:*",
                "eks:*",
                "elasticbeanstalk:*",
                "elasticloadbalancing:*",
                "es:*",
                "events:*",
                "glue:*",
                "guardduty:*",
                "health:*",
                "iam:*",
                "kms:*",
                "lambda:*",
                "lightsail:*",
                "logs:*",
                "ram:*",
                "rds:*",
                "redshift:*",
                "resource-explorer:*",
                "resource-groups:*",
                "route53:*",
                "route53domains:*",
                "route53resolver:*",
                "s3:*",
                "secretsmanager:*",
                "ses:*",
                "shield:*",
                "sns:*",
                "sqs:*",
                "ssm:*",
                "sts:*",
                "support:*",
                "tag:*",
                "trustedadvisor:*",
                "vpc:*",
                "waf:*",
                "wafv2:*",
                "waf-regional:*",
                "wellarchitected:*"
            ],
            "Resource": [
                "*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": [
                        "us-east-1",
                        "us-east-2",
                        "us-west-2"
                    ]
                }
            }
        },
        {
            "Sid": "Ec2RunInstanceCustomSize",
            "Effect": "Deny",
            "Action": "ec2:RunInstances",
            "Resource": [
                "arn:aws:ec2:*:*:instance/*"
            ],
            "Condition": {
                "ForAnyValue:StringNotLike": {
                    "ec2:InstanceType": [
                        "*.nano",
                        "*.micro",
                        "*.small",
                        "*.medium",
                        "*.large"
                    ]
                }
            }
        },
        {
            "Sid": "RdsFullAccessCustomSize",
            "Effect": "Deny",
            "Action": [
                "rds:CreateDBInstance",
                "rds:CreateDBCluster"
            ],
            "Resource": [
                "arn:aws:rds:*:*:db:*"
            ],
            "Condition": {
                "ForAnyValue:StringNotLike": {
                    "rds:DatabaseClass": [
                        "*.micro",
                        "*.small",
                        "*.medium",
                        "*.large"
                    ]
                }
            }
        }
    ]
}
EOF
}

#
# Customer Managed Policy: DeployMaster
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
                "athena:*",
                "budgets:*",
                "cloudfront:*",
                "cloudtrail:*",
                "cloudwatch:*",
                "config:*",
                "ecr:*",
                "elasticloadbalancing:*",
                "iam:*",
                "dynamodb:*",
                "ec2:*",
                "ecr:*",
                "glue:*",
                "iam:*",
                "logs:*",
                "route53:*",
                "route53domains:*",
                "s3:*",
                "sns:*",
                "ssm:*",
                "sqs:*",
                "vpc:*",
                "waf:*",
                "wafv2:*",
                "waf-regional:*"
            ],
            "Resource": [
                "*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": [
                        "us-east-1",
                        "us-east-2",
                        "us-west-2"
                    ]
                }
            }
        }
    ]
}
EOF
}

#
# Customer Managed Policy: FinOps Role Access + Group (backup-s3 Group)
#
resource "aws_iam_policy" "s3_put_gdrive_to_s3_backup" {
  name   = "AllowS3PutBackup"
  path   = "/"
  policy = data.aws_iam_policy_document.backup_s3_binbash_gdrive.json
}

data "aws_iam_policy_document" "backup_s3_binbash_gdrive" {
  statement {
    sid    = "ListAllMyBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::bb-shared-gdrive-backup"]
  }

  statement {
    sid    = "PutDeleteBucketObjetc"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::bb-shared-gdrive-backup/*"]
  }
}

resource "aws_iam_policy" "github_actions_oidc" {
  name        = "${local.environment}-github-actions-oidc"
  description = "Github OIDC integration for Github Actions"
  tags        = merge(local.tags, { Name = "github-oidc-workflows" })
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowLogin",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowList",
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeRepositories"
            ],
            "Resource": "arn:aws:ecr:${var.region}:${var.accounts.shared.id}:repository/*"
        },
        {
            "Sid": "AllowPush",
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:ListImages",
                "ecr:DescribeImages"
            ],
            "Resource": "arn:aws:ecr:${var.region}:${var.accounts.shared.id}:repository/demo-google-microservices-*"
        }
    ]
}
EOF
}
