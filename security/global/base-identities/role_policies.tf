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
                "secretsmanager:*",
                "sns:*",
                "ssm:*",
                "sso:*",
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