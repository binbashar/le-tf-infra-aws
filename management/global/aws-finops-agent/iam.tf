#=============================#
# Shared trust policy         #
#=============================#
locals {
  # Both roles are assumed by the FinOps Agent service. SetSourceIdentity stamps the
  # calling user's identity onto the session so agent-driven CloudTrail events are
  # attributable per user. SourceArn is scoped to any agentspace in this account;
  # tighten to a specific agent ID after CreateAgentSpace if desired.
  finops_agent_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "finops-agent.amazonaws.com" }
        Action    = ["sts:AssumeRole", "sts:SetSourceIdentity"]
        Condition = {
          StringEquals = { "aws:SourceAccount" = local.account_id }
          ArnLike      = { "aws:SourceArn" = "arn:aws:finops-agent:*:${local.account_id}:agentspace/*" }
        }
      }
    ]
  })
}

#=============================#
# Agent role (data access)    #
#=============================#
resource "aws_iam_role" "agent" {
  name               = var.agent_role_name
  assume_role_policy = local.finops_agent_trust_policy
  tags               = local.tags
}

resource "aws_iam_policy" "agent" {
  name        = "${var.agent_role_name}Policy"
  description = "FinOps Agent data-access permissions (Cost Explorer, Compute Optimizer, pricing, EventBridge managed rules). Mirrors AWS managed FinOpsAgentAgentPolicy; kept inline for preview-stability and git visibility."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FinOpsAgentDataAccess"
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetCostAndUsageWithResources",
          "ce:GetCostForecast",
          "ce:GetUsageForecast",
          "ce:GetDimensionValues",
          "ce:GetTags",
          "ce:GetCostCategories",
          "ce:GetCostAndUsageComparisons",
          "ce:GetCostComparisonDrivers",
          "ce:GetSavingsPlansCoverage",
          "ce:GetSavingsPlansUtilization",
          "ce:GetSavingsPlansUtilizationDetails",
          "ce:GetSavingsPlansPurchaseRecommendation",
          "ce:GetReservationCoverage",
          "ce:GetReservationUtilization",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetAnomalies",
          "ce:GetAnomalyMonitors",
          "ce:ListCostAllocationTags",
          "ce:ListCostAllocationTagBackfillHistory",
          "ce:DescribeCostCategoryDefinition",
          "ce:ListCostCategoryDefinitions",
          "budgets:ViewBudget",
          "cost-optimization-hub:GetRecommendation",
          "cost-optimization-hub:ListRecommendations",
          "cost-optimization-hub:ListRecommendationSummaries",
          "compute-optimizer:DescribeRecommendationExportJobs",
          "compute-optimizer:GetEnrollmentStatus",
          "compute-optimizer:GetEnrollmentStatusesForOrganization",
          "compute-optimizer:GetRecommendationSummaries",
          "compute-optimizer:GetEC2InstanceRecommendations",
          "compute-optimizer:GetEC2RecommendationProjectedMetrics",
          "compute-optimizer:GetAutoScalingGroupRecommendations",
          "compute-optimizer:GetEBSVolumeRecommendations",
          "compute-optimizer:GetLambdaFunctionRecommendations",
          "compute-optimizer:GetRecommendationPreferences",
          "compute-optimizer:GetEffectiveRecommendationPreferences",
          "compute-optimizer:GetECSServiceRecommendations",
          "compute-optimizer:GetECSServiceRecommendationProjectedMetrics",
          "compute-optimizer:GetLicenseRecommendations",
          "compute-optimizer:GetRDSDatabaseRecommendations",
          "compute-optimizer:GetRDSDatabaseRecommendationProjectedMetrics",
          "compute-optimizer:GetIdleRecommendations",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ecs:ListServices",
          "ecs:ListClusters",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "lambda:ListFunctions",
          "lambda:ListProvisionedConcurrencyConfigs",
          "organizations:ListAccounts",
          "organizations:DescribeOrganization",
          "organizations:DescribeAccount",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "pricing:DescribeServices",
          "pricing:GetAttributeValues",
          "pricing:GetProducts",
          "freetier:GetFreeTierUsage",
          "bcm-pricing-calculator:GetPreferences",
          "bcm-pricing-calculator:GetWorkloadEstimate",
          "bcm-pricing-calculator:ListWorkloadEstimateUsage",
          "bcm-pricing-calculator:ListWorkloadEstimates",
          "cloudtrail:LookupEvents",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:GetEventSelectors",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:StartQuery",
          "logs:GetQueryResults",
        ]
        Resource = "*"
      },
      {
        Sid    = "EventBridgeManagedRuleManagementWritePermissions"
        Effect = "Allow"
        Action = [
          "events:PutRule",
          "events:PutTargets",
          "events:DeleteRule",
          "events:RemoveTargets",
          "events:EnableRule",
          "events:DisableRule",
        ]
        Resource = "arn:aws:events:*:*:rule/*"
        Condition = {
          StringEquals = {
            "events:ManagedBy"    = "finops-agent.amazonaws.com"
            "aws:ResourceAccount" = "$${aws:PrincipalAccount}"
          }
        }
      },
      {
        Sid    = "EventBridgeManagedRuleManagementReadPermissions"
        Effect = "Allow"
        Action = [
          "events:DescribeRule",
          "events:ListTargetsByRule",
        ]
        Resource = "arn:aws:events:*:*:rule/*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = "$${aws:PrincipalAccount}"
          }
        }
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "agent" {
  role       = aws_iam_role.agent.name
  policy_arn = aws_iam_policy.agent.arn
}

#=============================#
# Operator role (web app)     #
#=============================#
resource "aws_iam_role" "operator" {
  name               = var.operator_role_name
  assume_role_policy = local.finops_agent_trust_policy
  tags               = local.tags
}

resource "aws_iam_policy" "operator" {
  name        = "${var.operator_role_name}Policy"
  description = "FinOps Agent web-app operator permissions (conversations, tasks, automations, documents). Mirrors AWS managed FinOpsAgentOperatorPolicy; kept inline for preview-stability and git visibility."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FinOpsAgentOperatorAccess"
        Effect = "Allow"
        Action = [
          "finops-agent:CreateConversation",
          "finops-agent:ListConversations",
          "finops-agent:CreateTurn",
          "finops-agent:GetTurn",
          "finops-agent:ListTurns",
          "finops-agent:CancelTurn",
          "finops-agent:AcceptAgentRequest",
          "finops-agent:RejectAgentRequest",
          "finops-agent:GetAgentRequest",
          "finops-agent:CreateTask",
          "finops-agent:GetTask",
          "finops-agent:ListTasks",
          "finops-agent:CancelTask",
          "finops-agent:CreateAutomation",
          "finops-agent:GetAutomation",
          "finops-agent:ListAutomations",
          "finops-agent:UpdateAutomation",
          "finops-agent:DeleteAutomation",
          "finops-agent:CreateDocument",
          "finops-agent:GetDocumentContent",
          "finops-agent:GetDocumentMetadata",
          "finops-agent:ListDocuments",
          "finops-agent:UpdateDocument",
          "finops-agent:DeleteDocument",
          "finops-agent:RestoreDocument",
          "finops-agent:DeleteArtifact",
          "finops-agent:GetArtifactContent",
          "finops-agent:GetArtifactMetadata",
          "finops-agent:ListArtifacts",
          "finops-agent:ListRecords",
          "finops-agent:SendFeedback",
        ]
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "operator" {
  role       = aws_iam_role.operator.name
  policy_arn = aws_iam_policy.operator.arn
}
