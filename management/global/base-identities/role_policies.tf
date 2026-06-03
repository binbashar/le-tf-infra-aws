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
                "dynamodb:*",
                "events:*",
                "iam:*",
                "logs:*",
                "s3:*",
                "kms:*",
                "lambda:*",
                "organizations:Describe*",
                "organizations:List*",
                "sso:ListInstances"
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
# Customer Managed Policy: aws-finops plugin read-only access
#
# Read-only AWS Billing & Cost Management permissions consumed by the `aws-finops`
# Claude Code plugin (skills: aws-finops-investigate, aws-finops-optimize,
# leverage-aws-creds-check) through the awslabs.billing-cost-management-mcp-server
# MCP server. Attached to the DeployMaster role so any management profile that
# assumes DeployMaster can run the plugin without static keys.
#
# NOTE: intentionally NO `aws:RequestedRegion` condition — Cost Explorer, Budgets,
# Cost Optimization Hub, Savings Plans, Pricing and Free Tier are global / us-east-1
# endpoints and a region condition can silently break them. Read verbs only.
#
resource "aws_iam_policy" "aws_finops_readonly_access" {
  name        = "aws_finops_readonly_access"
  description = "Read-only Billing & Cost Management access for the aws-finops Claude Code plugin"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AwsFinOpsReadOnly",
            "Effect": "Allow",
            "Action": [
                "budgets:Describe*",
                "budgets:ViewBudget",
                "ce:Describe*",
                "ce:Get*",
                "ce:List*",
                "compute-optimizer:Describe*",
                "compute-optimizer:Get*",
                "compute-optimizer:List*",
                "cost-optimization-hub:Get*",
                "cost-optimization-hub:List*",
                "freetier:GetFreeTierUsage",
                "organizations:Describe*",
                "organizations:List*",
                "pricing:DescribeServices",
                "pricing:GetAttributeValues",
                "pricing:GetProducts",
                "savingsplans:Describe*",
                "savingsplans:List*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
