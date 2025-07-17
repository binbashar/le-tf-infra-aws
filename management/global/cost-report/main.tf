#
# Cost Report:
# This helper will run on the given schedule in order to fetch AWS costs for
# the past week, build a report and post it to Slack.
# --------------------------------------------------
# Known Issues:
#  1. Leverage toolbox image doesn't have PIP
#  2. tried to run outside of Leverage, but the packager couldn't find the python executable
#  3. tried the same as above but via docker using the following, that worked but it is not ideal

module "cost_report" {
  source = "github.com/binbashar/terraform-aws-lambda.git?ref=v8.0.1"

  publish       = true
  function_name = "${var.project}-${var.environment}-cost-report"
  description   = "Send account daily cost data to Slack"
  handler       = "handler.lambda_handler"
  runtime       = "python3.9"
  memory_size   = 128
  timeout       = 10
  source_path   = "src/"

  # Had to build the script dependencies and create the package via docker (issue #3)
  build_in_docker = true

  trigger_on_package_timestamp = false

  environment_variables = {
    # How many items to show in the report
    LENGTH = var.report_items_length
    # How to group the items in the report
    GROUP_BY = var.report_group_by
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
            "iam:ListAccountAliases"
          ],
          "Resource": ["*"]
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
  description         = "Trigger the cost-report-helper every day at 6AM UTC"
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
