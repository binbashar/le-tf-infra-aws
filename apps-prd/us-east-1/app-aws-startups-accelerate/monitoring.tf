#
# CloudWatch alarms on CloudFront error rates, wired to the existing
# notifications layer SNS -> Slack pipeline in this account.
#
# CloudFront metrics are emitted in us-east-1 with Region = "Global".
#
resource "aws_cloudwatch_metric_alarm" "cf_5xx_error_rate" {
  alarm_name          = "${var.project}-${var.environment}-${local.app_subdomain}-cf-5xx-error-rate"
  alarm_description   = "CloudFront 5xxErrorRate above ${var.alarm_5xx_error_rate_threshold}% for ${local.app_fqdn}"
  namespace           = "AWS/CloudFront"
  metric_name         = "5xxErrorRate"
  statistic           = "Average"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.alarm_5xx_error_rate_threshold
  period              = 300
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = module.aws_startups_accelerate.cf_id
    Region         = "Global"
  }

  alarm_actions = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]
  ok_actions    = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "cf_total_error_rate" {
  alarm_name          = "${var.project}-${var.environment}-${local.app_subdomain}-cf-total-error-rate"
  alarm_description   = "CloudFront TotalErrorRate above ${var.alarm_total_error_rate_threshold}% for ${local.app_fqdn}"
  namespace           = "AWS/CloudFront"
  metric_name         = "TotalErrorRate"
  statistic           = "Average"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.alarm_total_error_rate_threshold
  period              = 300
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = module.aws_startups_accelerate.cf_id
    Region         = "Global"
  }

  alarm_actions = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]
  ok_actions    = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]

  tags = local.tags
}
