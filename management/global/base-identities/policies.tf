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
