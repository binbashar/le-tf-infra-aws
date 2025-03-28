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
                "apigateway:*",
                "appsync:*",
                "autoscaling:*",
                "application-autoscaling:*",
                "aws-portal:*",
                "backup:*",
                "backup-storage:*",
                "budgets:*",
                "ce:*",
                "cloudformation:*",
                "cloudfront:*",
                "cloudtrail:*",
                "cloudwatch:*",
                "compute-optimizer:*",
                "config:*",
                "dlm:*",
                "dynamodb:*",
                "ec2:*",
                "ecr:*",
                "ecs:*",
                "eks:*",
                "elasticloadbalancing:*",
                "events:*",
                "guardduty:*",
                "health:*",
                "iam:*",
                "kms:*",
                "lambda:*",
                "logs:*",
                "ram:*",
                "rds:*",
                "redshift:*",
                "route53:*",
                "route53domains:*",
                "route53resolver:*",
                "s3:*",
                "ses:*",
                "shield:*",
                "sns:*",
                "sqs:*",
                "ssm:*",
                "support:*",
                "tag:*",
                "transfer:*",
                "trustedadvisor:*",
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
                "dynamodb:*",
                "ec2:*",
                "ecr:*",
                "eks:*",
                "ecr:*",
                "elasticloadbalancing:*",
                "iam:*",
                "logs:*",
                "rds:*",
                "route53:*",
                "route53domains:*",
                "s3:*",
                "sns:*",
                "ssm:*",
                "sqs:*",
                "vpc:*",
                "waf:*",
                "wafv2:*",
                "waf-regional:*",
                "kms:*"
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

#
# External DNS policy
#
resource "aws_iam_policy" "alb_ingress" {
  name        = "alb_ingress"
  description = "ALB Ingress permissions"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole",
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeTags",
                "ec2:GetCoipPoolUsage",
                "ec2:DescribeCoipPools",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient",
                "acm:ListCertificates",
                "acm:DescribeCertificate",
                "iam:ListServerCertificates",
                "iam:GetServerCertificate",
                "waf-regional:GetWebACL",
                "waf-regional:GetWebACLForResource",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL",
                "wafv2:GetWebACL",
                "wafv2:GetWebACLForResource",
                "wafv2:AssociateWebACL",
                "wafv2:DisassociateWebACL",
                "shield:GetSubscriptionState",
                "shield:DescribeProtection",
                "shield:CreateProtection",
                "shield:DeleteProtection"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateSecurityGroup"
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DeleteRule"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeleteTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:SetWebAcl",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:ModifyRule"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#
# Velero backups policy
#
resource "aws_iam_policy" "velero_backups" {
  name        = "velero_backups_access"
  description = "Permissions for Velero to manage EC2 and Backup Bucket"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::le-apps-devstg-valero/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::le-apps-devstg-valero"
            ]
        }
    ]
}
EOF
}

#
# Customer Managed Policy: Costs Explorer Access
#
# This policy is attached to the LambdaCostsExplorerAccess role and allows the Lambda function to access the Cost Explorer API.
resource "aws_iam_role_policy_attachment" "lambda_costs_explorer_access" {
  policy_arn = aws_iam_policy.lambda_costs_explorer_access.arn
  role       = module.iam_assumable_role_lambda_costs_explorer_access.iam_role_name
}

resource "aws_iam_policy" "lambda_costs_explorer_access" {
  name   = "policy_document_lambda_costs_explorer_access"
  policy = data.aws_iam_policy_document.lambda_costs_explorer_access.json
}

data "aws_iam_policy_document" "lambda_costs_explorer_access" {
  statement {
    sid = "CostsExplorerAccess"
    actions = [
      "ce:DescribeCostCategoryDefinition",
      "ce:GetRightsizingRecommendation",
      "ce:GetCostAndUsage",
      "ce:GetSavingsPlansUtilization",
      "ce:GetAnomalies",
      "ce:GetReservationPurchaseRecommendation",
      "ce:ListCostCategoryDefinitions",
      "ce:GetCostForecast",
      "ce:GetPreferences",
      "ce:GetReservationUtilization",
      "ce:GetCostCategories",
      "ce:GetSavingsPlansPurchaseRecommendation",
      "ce:GetDimensionValues",
      "ce:GetSavingsPlansUtilizationDetails",
      "ce:GetAnomalySubscriptions",
      "ce:GetCostAndUsageWithResources",
      "ce:DescribeReport",
      "ce:GetReservationCoverage",
      "ce:GetSavingsPlansCoverage",
      "ce:GetAnomalyMonitors",
      "ce:DescribeNotificationSubscription",
      "ce:GetTags",
      "ce:GetUsageForecast",
      "ce:GetCostAndUsage"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "north_cloud_tool_access" {
  name        = "NorthCostAndUsageReadOnlyPolicy"
  description = "Read-only policy for North Inc. cost and usage"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NorthCostAndUsageReadOnlyPolicyID"
        Effect = "Allow"
        Action = [
          "ce:Get*",
          "ce:Describe*",
          "ce:List*",
          "ce:Start*",
          "account:GetAccountInformation",
          "billing:Get*",
          "payments:List*",
          "payments:Get*",
          "tax:List*",
          "tax:Get*",
          "consolidatedbilling:Get*",
          "consolidatedbilling:List*",
          "invoicing:List*",
          "invoicing:Get*",
          "cur:Get*",
          "cur:Validate*",
          "freetier:Get*",
          "ec2:DescribeCapacity*",
          "ec2:DescribeReservedInstances*",
          "ec2:DescribeSpot*",
          "rds:DescribeReserved*",
          "rds:DescribeDBRecommendations",
          "rds:DescribeAccountAttributes",
          "ecs:DescribeCapacityProviders",
          "es:DescribeReserved*"
        ]
        Resource = "*"
      }
    ]
  })
}
