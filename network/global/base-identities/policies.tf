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
                "autoscaling:*",
                "application-autoscaling:*",
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
                "dlm:*",
                "dynamodb:*",
                "ec2:*",
                "ecr:*",
                "ecr-public:*",
                "ecs:*",
                "eks:*",
                "elasticloadbalancing:*",
                "es:*",
                "events:*",
                "fms:*",
                "guardduty:*",
                "health:*",
                "iam:*",
                "kms:*",
                "lambda:*",
                "logs:*",
                "network-firewall:*",
                "networkmanager:*",
                "ram:*",
                "rds:*",
                "redshift:*",
                "resource-explorer:*",
                "resource-groups:*",
                "route53:*",
                "route53domains:*",
                "route53resolver:*",
                "s3:*",
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
                "organizations:DescribeOrganization",
                "organizations:ListAccounts"
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
# User Managed Policy: SecOps Access
#
resource "aws_iam_policy" "secops_access" {
  name        = "secops_access"
  description = "Services enabled for SecOps role"

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
                "access-analyzer:*",
                "acm:*",
                "apigateway:*",
                "appsync:*",
                "aws-portal:*",
                "backup:*",
                "backup-storage:*",
                "ce:*",
                "cloudformation:*",
                "cloudtrail:*",
                "cloudwatch:*",
                "config:*",
                "dlm:*",
                "dynamodb:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "events:*",
                "fms:*",
                "guardduty:*",
                "health:*",
                "iam:*",
                "kms:*",
                "lambda:*",
                "logs:*",
                "organizations:Describe*",
                "organizations:List*",
                "route53:*",
                "route53domains:*",
                "route53resolver:*",
                "s3:*",
                "sns:*",
                "ssm:*",
                "support:*",
                "tag:*",
                "trustedadvisor:*",
                "vpc:*",
                "waf:*",
                "waf-regional:*",
                "wafv2:*"

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
                "iam:*",
                "network-firewall:*",
                "logs:*",
                "organizations:DescribeOrganization",
                "organizations:ListAccounts",
                "ram:*",
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
# Customer Managed Policy: Grafana
#
resource "aws_iam_policy" "grafana_permissions" {
  name        = "grafana_permissions"
  description = "Grafana Permissions"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GrafanaReadCloudWatchMetrics",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:DescribeAlarmsForMetric",
                "cloudwatch:DescribeAlarmHistory",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:GetMetricData"
            ],
            "Resource": "*"
        },
        {
            "Sid": "GrafanaReadEC2InstancesTagsAndRegions",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ec2:DescribeInstances",
                "ec2:DescribeRegions"
            ],
            "Resource": "*"
        },
        {
            "Sid": "GrafanaReadResourcesTags",
            "Effect" : "Allow",
            "Action" : "tag:GetResources",
            "Resource" : "*"
        }
    ]
}
EOF
}
