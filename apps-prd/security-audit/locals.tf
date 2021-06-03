locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  alarm_sufix = "${var.environment}-account"

  metrics = [
    for metric in var.metrics : {
      metric_name               = local.alarm_suffix != null ? join("-", tolist([lookup(metric, "metric_name", null), local.alarm_suffix])) : lookup(metric, "metric_name", null)
      filter_pattern            = lookup(metric, "filter_pattern", null)
      metric_namespace          = lookup(metric, "metric_namespace", null)
      metric_value              = lookup(metric, "metric_value", null)
      alarm_name                = lookup(metric, "alarm_name", null)
      alarm_comparison_operator = lookup(metric, "alarm_comparison_operator", null)
      alarm_evaluation_periods  = lookup(metric, "alarm_evaluation_periods", null)
      alarm_period              = lookup(metric, "alarm_period", null)
      alarm_statistic           = lookup(metric, "alarm_statistic", null)
      alarm_treat_missing_data  = lookup(metric, "alarm_treat_missing_data", null)
      alarm_threshold           = lookup(metric, "alarm_threshold", null)
      alarm_description         = lookup(metric, "alarm_description", null)
    }
  ]
}
