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
  # 128 MB left little headroom (104 MB used with block E); CPU scales with memory too
  memory_size = 256
  timeout     = 60
  source_path = "src/"

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
    # Break the largest N threshold alerts down by account and usage type (one request each; 0: off)
    DRILLDOWN_MAX = var.report_drilldown_max
    # The Slack webhook URL for sending the report; used only without the bot below, or when the bot cannot post
    SLACK_WEBHOOK_SECRET_ID = "arn:aws:secretsmanager:${var.region}:${var.accounts.shared.id}:secret:/notifications/slack/cost-reports-m8z5y2"
    # The Slack app's bot token (chat:write) and its channel: the bot posts the report and replies in its thread (empty channel: webhook only)
    SLACK_BOT_TOKEN_SECRET_ID = "arn:aws:secretsmanager:${var.region}:${var.accounts.shared.id}:secret:/notifications/slack/cost-reports-bot-hIQKFM"
    SLACK_CHANNEL_ID          = var.report_slack_channel_id
    # Reply in the report's thread with the cost by linked account (needs the bot; one more request)
    SHOW_ACCOUNTS = var.report_show_accounts

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
          "Sid": "ReadSlackSecrets",
          "Effect": "Allow",
          "Action": "secretsmanager:GetSecretValue",
          "Resource": "arn:aws:secretsmanager:${var.region}:${var.accounts.shared.id}:secret:/notifications/slack/cost-reports-*"
        },
        {
          "Sid": "DecryptKmsEncryptedSlackSecrets",
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

#
# Alarm when a run fails -- out of memory, timeout or any exception -- since
# that day's report then never reaches Slack. Notifies the costs SNS topic.
#
resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "${var.project}-${var.environment}-cost-report-errors"
  alarm_description   = "The cost report Lambda failed: that day's report did not go out. Check its CloudWatch logs."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = module.cost_report.lambda_function_name }
  statistic           = "Sum"
  period              = 3600
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  # The function runs once a day: the hours without a run are not a failure
  treat_missing_data = "notBreaching"
  alarm_actions      = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_costs]

  tags = local.tags
}
