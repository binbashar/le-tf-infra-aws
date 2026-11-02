#
# Alarm: the report raises on any failure, so one error means no email that month
#
module "errors_alarm" {
  source = "github.com/binbashar/terraform-aws-cloudwatch-alarms.git?ref=v1.3.3"

  # The module names the alarm from its labels (lowercased), not from
  # alarm_name: name + label_order give the function's name.
  # alarm_name is still a required input, so keep it in step.
  name        = "${local.function_name}-errors"
  label_order = ["name"]
  alarm_name  = "${local.function_name}-errors"

  alarm_description   = "The monthly cost email report failed: no email was sent. Check the function's logs, fix, and invoke it again."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  actions_enabled     = true

  dimensions = {
    FunctionName = module.cost_email_report.lambda_function_name
  }

  alarm_actions = [var.alarm_sns_topic_arn != "" ? var.alarm_sns_topic_arn : data.terraform_remote_state.notifications[0].outputs.sns_topic_arn_monitoring]
}
