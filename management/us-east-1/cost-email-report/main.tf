#
# Monthly cost email report
# --------------------------------------------------
# Packaging: src/ uses only the Python standard library plus boto3 (bundled in
# the Lambda runtime), so the module zips src/ as-is: no pip, no Docker.
#
locals {
  function_name  = "${var.project}-${var.environment}-cost-email-report"
  sender_address = regex("[^<>[:space:]]+@[^<>[:space:]]+", var.sender)
}

data "aws_caller_identity" "current" {}

module "cost_email_report" {
  source = "github.com/binbashar/terraform-aws-lambda.git?ref=v8.0.1"

  function_name = local.function_name
  description   = "Email last month's AWS cost report for the organization"
  handler       = "report.lambda_handler"
  runtime       = "python3.13"
  memory_size   = 256
  timeout       = 120
  source_path   = "src/"

  # No third-party dependencies to install (see "Packaging" above)
  build_in_docker              = false
  trigger_on_package_timestamp = false

  # EventBridge invokes $LATEST asynchronously: no published versions, and no
  # retries, so a failure after the email went out cannot send it twice. A
  # failed month raises, fires the alarm, and is sent again by hand.
  publish                                   = false
  create_async_event_config                 = true
  create_current_version_async_event_config = false
  maximum_retry_attempts                    = 0
  create_current_version_allowed_triggers   = false
  allowed_triggers = {
    MonthlySchedule = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.schedule.arn
    }
  }

  environment_variables = {
    ORGANIZATION_NAME       = var.organization_name
    SENDER                  = var.sender
    RECIPIENTS              = join(",", var.recipients)
    BINBASH_RECIPIENTS      = join(",", var.binbash_recipients)
    BINBASH_REPORTING_UNTIL = var.binbash_reporting_until
    ACCOUNT_ID              = data.aws_caller_identity.current.account_id
    BUDGET_NAME             = var.budget_name
    CHANGE_MIN_USD          = tostring(var.change_min_usd)
    TOP_N                   = tostring(var.top_n)
    ANOMALY_MIN_USD         = tostring(var.anomaly_min_usd)
    UNTAGGED_TAG_KEY        = var.untagged_tag_key
  }

  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "ReadCostsForTheOrganization"
          Effect = "Allow"
          Action = [
            "ce:GetCostAndUsage",
            "ce:GetCostForecast",
            "ce:GetAnomalies",
            "ce:GetSavingsPlansCoverage",
            "organizations:ListAccounts",
            "billing:GetCredits",
          ]
          Resource = "*"
        },
        {
          # Any identity of this account, but only from the configured sender
          Sid      = "SendTheReport"
          Effect   = "Allow"
          Action   = "ses:SendEmail"
          Resource = "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:identity/*"
          Condition = {
            StringEquals = { "ses:FromAddress" = local.sender_address }
          }
        },
      ],
      var.budget_name == "" ? [] : [
        {
          Sid      = "ReadTheBudget"
          Effect   = "Allow"
          Action   = "budgets:ViewBudget"
          Resource = "arn:aws:budgets::${data.aws_caller_identity.current.account_id}:budget/${var.budget_name}"
        },
      ],
    )
  })

  cloudwatch_logs_retention_in_days = 90

  tags = local.tags
}

#
# Schedule
#
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = local.function_name
  description         = "Send last month's cost report (${var.schedule_expression}, UTC)"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "CostEmailReport"
  arn       = module.cost_email_report.lambda_function_arn
}
