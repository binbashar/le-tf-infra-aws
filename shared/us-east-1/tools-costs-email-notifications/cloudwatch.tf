resource "aws_cloudwatch_event_rule" "monthly_services_usage_scheduler" {
  description         = "To Trigger Lambda Function on scheduled time"
  name                = "MontlyServicesUsageScheduler"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.monthly_services_usage_scheduler.name
  target_id = "MonthlyServicesUsageLambdaTarget"
  arn       = aws_lambda_function.monthly_services_usage.arn
}

# CloudWatch Alarm for Lambda Errors
module "lambda_error_alarm" {
  source = "github.com/binbashar/terraform-aws-cloudwatch-alarms.git?ref=1.3.2"

  alarm_name          = "MonthlyServicesUsageLambdaErrors"
  alarm_description   = "Alert when MonthlyServicesUsage Lambda function encounters errors"
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
    FunctionName = aws_lambda_function.monthly_services_usage.function_name
  }

  alarm_actions = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring_sec]
}
