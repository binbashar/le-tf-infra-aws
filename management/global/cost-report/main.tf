#
# Cost Report:
# This helper will run on the given schedule in order to fetch AWS costs for
# the past week, build a report and post it to Slack.
# --------------------------------------------------
# Packaging: src/ uses only the Python standard library plus boto3 (bundled in
# the Lambda runtime), so there is no requirements.txt and the module simply
# zips src/ -- no pip, no Docker, no local Python matching the runtime.
# Adding a requirements.txt brings all of that back: pip then has to run for
# the Lambda runtime, which in practice means build_in_docker = true and a
# running Docker daemon on whoever applies.

module "cost_report" {
  source = "github.com/binbashar/terraform-aws-lambda.git?ref=v8.0.1"

  publish       = true
  function_name = "${var.project}-${var.environment}-cost-report"
  description   = "Send account daily cost data to Slack"
  handler       = "handler.lambda_handler"
  runtime       = "python3.13"
  memory_size   = 128
  timeout       = 30
  source_path   = "src/"

  # No third-party dependencies to install (see "Packaging" above)
  build_in_docker = false

  trigger_on_package_timestamp = false

  environment_variables = {
    # How many items to show in the report
    LENGTH = var.report_items_length
    # How to group the items in the report
    GROUP_BY = var.report_group_by
    # List any item whose cost moved at least this much (USD), even outside the top LENGTH
    MOVER_MIN_USD = var.report_mover_min_usd
    # Cost Explorer in the payer account returns the whole Organization's bill
    REPORT_SCOPE = "the AWS Organization"
    # The AWS Budget shown in the month summary (empty: none)
    BUDGET_NAME = var.report_budget_name
    # Alert on an item that moved by both this much (USD) and this much (%) vs. a typical day
    ALERT_MIN_USD = var.report_alert_min_usd
    ALERT_MIN_PCT = var.report_alert_min_pct
    # Slack mention added to alerts, e.g. "<!here>" or "<!subteam^S0123>" (empty: none)
    ALERT_MENTION = var.report_alert_mention
    # "full": the full report every day; "compact": one line on quiet days, full report on alerts and on FULL_REPORT_WEEKDAY
    DAILY_MODE          = var.report_daily_mode
    FULL_REPORT_WEEKDAY = var.report_full_report_weekday
    # Show Cost Anomaly Detection anomalies without feedback that ended in the last N days (0: off)
    ANOMALY_DAYS = var.report_anomaly_days
    # The Slack webhook URL for sending the report
    SLACK_WEBHOOK_SECRET_ID = "arn:aws:secretsmanager:${var.region}:${var.accounts.shared.id}:secret:/notifications/slack/cost-reports-m8z5y2"

    # Other parameters you may want to explore
    # AWS_ACCOUNT_NAME      = ""
    # CREDITS_EXPIRE_DATE     = "01-15-2026"
    # CREDITS_REMAINING_AS_OF = "01-15-2026"
    # CREDITS_REMAINING       = "500"
  }

  # Grant this Lambda permissions through existing policies
  attach_policies    = true
  number_of_policies = 0
  policies           = []

  # Grant this Lambda permissions through ad-hoc policies
  attach_policy_jsons    = true
  number_of_policy_jsons = 1
  policy_jsons = [
    <<-EOT
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "QueryCostExplorer",
          "Effect": "Allow",
          "Action": [
            "ce:GetCostAndUsage",
            "ce:GetAnomalies",
            "iam:ListAccountAliases"
          ],
          "Resource": ["*"]
        },
        {
          "Sid": "ReadBudget",
          "Effect": "Allow",
          "Action": "budgets:ViewBudget",
          "Resource": "arn:aws:budgets::${var.accounts.management.id}:budget/${var.report_budget_name}"
        },
        {
          "Sid": "ReadSlackWebhookSecret",
          "Effect": "Allow",
          "Action": "secretsmanager:GetSecretValue",
          "Resource": "arn:aws:secretsmanager:${var.region}:${var.accounts.shared.id}:secret:/notifications/slack/cost-reports-*"
        },
        {
          "Sid": "DecryptKmsEncryptedSlackWebhookSecret",
          "Effect": "Allow",
          "Action": "kms:Decrypt",
          "Resource": "arn:aws:kms:${var.region}:${var.accounts.shared.id}:key/cef0e7ad-2dcc-4a31-89bf-c3ea0cab5a4c"
        }
      ]
    }
    EOT
  ]

  # Logs retention
  cloudwatch_logs_retention_in_days = 7

  tags = local.tags
}

#
# Use the following resources to trigger the Cost Report Helper on a daily basis.
#
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "${var.project}-${var.environment}-cost-report-helper-daily"
  description         = "Trigger the cost-report-helper on ${var.report_run_schedule} (UTC)"
  schedule_expression = var.report_run_schedule
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "SendToLambda"
  arn       = module.cost_report.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.cost_report.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}
