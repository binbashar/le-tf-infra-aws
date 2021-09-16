#
# Policies attached to Roles
#

#
# User Managed Policy: DevOps Access
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
                "access-analyzer:*",
                "acm:*",
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
                "events:*",
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
                "vpc:*"
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
