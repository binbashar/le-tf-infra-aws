locals {

  metrics = [
    {
      metric_name               = "AuthorizationFailureCount"
      filter_pattern            = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
      metric_namespace          = var.metric_namespace
      metric_value              = null
      alarm_name                = null
      alarm_comparison_operator = null
      alarm_evaluation_periods  = null
      alarm_period              = "600"
      alarm_statistic           = null
      alarm_treat_missing_data  = null
      alarm_threshold           = "10"
      alarm_description         = "Alarms when an unauthorized API call is made."
    },
    {
      metric_name               = "S3BucketActivityEventCount"
      filter_pattern            = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
      metric_namespace          = var.metric_namespace
      metric_value              = null
      alarm_name                = null
      alarm_comparison_operator = null
      alarm_evaluation_periods  = null
      alarm_period              = null
      alarm_statistic           = null
      alarm_treat_missing_data  = null
      alarm_threshold           = null
      alarm_description         = "Alarms when an unauthorized API call is made."
    },
  ]

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
