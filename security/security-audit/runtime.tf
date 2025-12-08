
locals {
  # ===========================================
  # REGION CONFIGURATION
  # -------------------------------------------
  # Purpose: Determine the current region for resource deployment
  # ===========================================
  region = var.region == null ? data.aws_region.current.name : var.region

  # ===========================================
  # ALARM CONFIGURATION
  # -------------------------------------------
  # Purpose: Define alarm suffix and default alarm settings
  # ===========================================
  alarm_suffix = var.monitoring_settings.metric.alarm_suffix != null ? var.monitoring_settings.metric.alarm_suffix : "${var.environment}-account"

  alarm_defaults = {
    period              = 300 // 5 min
    threshold           = 1
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    statistic           = "Sum"
    treat_missing_data  = "notBreaching"
  }

  # Layer name
  layer_name = "security-audit"

  # ===========================================
  # METRICS PROCESSING
  # -------------------------------------------
  # Purpose: Process and transform metrics configuration for CloudWatch alarms
  # ===========================================
  metrics = {
    for metric in var.monitoring_settings.metric.metrics : local.alarm_suffix != null ? join("-", tolist([lookup(metric, "metric_name", null), local.alarm_suffix])) : lookup(metric, "metric_name", null) => {
      metric_name               = lookup(metric, "metric_name", null)
      filter_pattern            = lookup(metric, "filter_pattern", null)
      metric_namespace          = var.monitoring_settings.metric.namespace != null ? var.monitoring_settings.metric.namespace : lookup(metric, "metric_namespace", null)
      metric_value              = lookup(metric, "metric_value", null)
      alarm_name                = local.alarm_suffix != null ? join("-", tolist([lookup(metric, "metric_name", null), local.alarm_suffix, "alarm"])) : "${lookup(metric, "metric_name", null)}-alarm"
      alarm_comparison_operator = lookup(metric, "alarm_comparison_operator", null)
      alarm_evaluation_periods  = lookup(metric, "alarm_evaluation_periods", null)
      alarm_period              = lookup(metric, "alarm_period", local.alarm_defaults["period"])
      alarm_statistic           = lookup(metric, "alarm_statistic", null)
      alarm_treat_missing_data  = lookup(metric, "alarm_treat_missing_data", null)
      alarm_threshold           = lookup(metric, "alarm_threshold", local.alarm_defaults["threshold"])
      alarm_description         = lookup(metric, "alarm_description", null)
      alarm_comparison_operator = lookup(metric, "alarm_comparison_operator", local.alarm_defaults["comparison_operator"])
      alarm_evaluation_periods  = lookup(metric, "alarm_evaluation_periods", local.alarm_defaults["evaluation_periods"])
      alarm_statistic           = lookup(metric, "alarm_statistic", local.alarm_defaults["statistic"])
      alarm_treat_missing_data  = lookup(metric, "alarm_treat_missing_data", local.alarm_defaults["treat_missing_data"])
    }
  }

  # ===========================================
  # STANDARD TAGS FOR ALL RESOURCES IN THIS LAYER
  # -------------------------------------------
  # Purpose: Provide a consistent tagging baseline across resources
  # created by this module. These are merged with per-resource tags
  # when applicable.
  # ===========================================
  tags = {
    Name      = "${var.project}-${var.environment}-cloudtrail-org"
    Namespace = var.project
    Stage     = var.environment
    Layer     = local.layer_name
  }
}

