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