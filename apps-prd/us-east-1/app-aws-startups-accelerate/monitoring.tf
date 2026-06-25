#
# CloudWatch alarms on CloudFront error rates, wired to the existing
# notifications layer SNS -> Slack pipeline in this account.
#
# CloudFront metrics are emitted in us-east-1 with Region = "Global".
#
# Low-traffic guard: *ErrorRate are percentage metrics, so on a near-idle
# static site a handful of internet background-radiation scanner 404s (probes
# for /.env, /wp-config.php, /.git/config, ...) reads as ~100% and pages a
# false alarm. Each alarm therefore evaluates a metric-math expression that
# gates the error rate on a minimum request volume per period
# (var.alarm_min_requests_per_period): below the floor the expression reports
# 0 and the alarm stays OK; at or above it the true error rate is evaluated.
#
resource "aws_cloudwatch_metric_alarm" "cf_5xx_error_rate" {
  alarm_name          = "${var.project}-${var.environment}-${local.app_subdomain}-cf-5xx-error-rate"
  alarm_description   = "CloudFront 5xxErrorRate >= ${var.alarm_5xx_error_rate_threshold}% over a period with >= ${var.alarm_min_requests_per_period} requests for ${local.app_fqdn}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.alarm_5xx_error_rate_threshold
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "gated_5xx_rate"
    expression  = "IF(requests >= ${var.alarm_min_requests_per_period}, rate_5xx, 0)"
    label       = "5xxErrorRate (gated on >= ${var.alarm_min_requests_per_period} req/period)"
    return_data = true
  }

  metric_query {
    id          = "requests"
    return_data = false
    metric {
      namespace   = "AWS/CloudFront"
      metric_name = "Requests"
      period      = 300
      stat        = "Sum"
      dimensions = {
        DistributionId = module.aws_startups_accelerate.cf_id
        Region         = "Global"
      }
    }
  }

  metric_query {
    id          = "rate_5xx"
    return_data = false
    metric {
      namespace   = "AWS/CloudFront"
      metric_name = "5xxErrorRate"
      period      = 300
      stat        = "Average"
      dimensions = {
        DistributionId = module.aws_startups_accelerate.cf_id
        Region         = "Global"
      }
    }
  }

  alarm_actions = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]
  ok_actions    = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "cf_total_error_rate" {
  alarm_name          = "${var.project}-${var.environment}-${local.app_subdomain}-cf-total-error-rate"
  alarm_description   = "CloudFront TotalErrorRate >= ${var.alarm_total_error_rate_threshold}% over a period with >= ${var.alarm_min_requests_per_period} requests for ${local.app_fqdn}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.alarm_total_error_rate_threshold
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "gated_total_rate"
    expression  = "IF(requests >= ${var.alarm_min_requests_per_period}, rate_total, 0)"
    label       = "TotalErrorRate (gated on >= ${var.alarm_min_requests_per_period} req/period)"
    return_data = true
  }

  metric_query {
    id          = "requests"
    return_data = false
    metric {
      namespace   = "AWS/CloudFront"
      metric_name = "Requests"
      period      = 300
      stat        = "Sum"
      dimensions = {
        DistributionId = module.aws_startups_accelerate.cf_id
        Region         = "Global"
      }
    }
  }

  metric_query {
    id          = "rate_total"
    return_data = false
    metric {
      namespace   = "AWS/CloudFront"
      metric_name = "TotalErrorRate"
      period      = 300
      stat        = "Average"
      dimensions = {
        DistributionId = module.aws_startups_accelerate.cf_id
        Region         = "Global"
      }
    }
  }

  alarm_actions = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]
  ok_actions    = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]

  tags = local.tags
}
