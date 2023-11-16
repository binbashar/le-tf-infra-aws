resource "aws_cloudwatch_event_rule" "monthly_services_usage_scheduler" {
  description = "To Trigger Lambda Function on scheduled time"
  name = "MontlyServicesUsageScheduler"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.monthly_services_usage_scheduler.name
  target_id = "MonthlyServicesUsageLambdaTarget"
  arn       = aws_lambda_function.monthly_services_usage.arn
}
