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
                "aws-portal:*",
                "backup:*",
                "backup-storage:*",
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
                "ecr:*",
                "elasticloadbalancing:*",
                "iam:*",
                "dynamodb:*",
                "ec2:*",
                "ecr:*",
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
# Customer Managed Policy: Costs Explorer Access
#
# This policy is attached to the LambdaCostsExplorerAccess role and allows the Lambda function to access the Cost Explorer API.
resource "aws_iam_role_policy_attachment" "lambda_costs_explorer_access" {
  policy_arn = aws_iam_policy.lambda_costs_explorer_access.arn
  role       = module.iam_assumable_role_lambda_costs_explorer_access.iam_role_name
}

resource "aws_iam_policy" "lambda_costs_explorer_access" {
  name        = "policy_document_lambda_costs_explorer_access"
  policy      = data.aws_iam_policy_document.lambda_costs_explorer_access.json
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