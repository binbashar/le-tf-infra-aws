#
# Alarms on lost applications, wired to the notifications layer's SNS -> Lambda ->
# Slack pipeline — the same topic app-binbash-web/monitoring.tf notifies.
#
# This layer has no datastore (spec §8.4), so a submission that does not reach the
# hiring inbox exists only as a traceback in the Lambda's log group. These two
# alarms are what turns that into a page instead of a discovery weeks later.
#
# WHY A LOG METRIC FILTER AND NOT JUST AWS/Lambda Errors:
#
# lambda_handler catches every exception and RETURNS a 500 payload rather than
# letting it escape (lambda_function.py:388-399). To Lambda that is a *successful*
# invocation, so `Errors` stays at 0 through exactly the failure this layer needs
# to know about — an SES send that was denied, throttled or rejected. An
# `Errors >= 1` alarm on its own would have been decorative.
#
# So the two alarms below cover disjoint halves:
#   send_failures  — the handler caught something and answered 500. The real
#                    "application lost" signal. Comes from the log group.
#   function_errors — the handler never got to answer: timeout, OOM, or a
#                    cold-start import failure. No log line of ours exists, so
#                    only the Lambda-level metric sees it.
#

#
# Matches both of the handler's error log lines. `?` is CloudWatch's OR for
# unstructured patterns, and both are substring matches, so this survives a
# change to the runtime's log format (TEXT vs JSON) in a way an `[ERROR]`
# level-prefix match would not.
#
# Keep these two strings in sync with lambda_function.py's LOGGER.exception()
# calls — there is no compiler to catch a rename here.
#
resource "aws_cloudwatch_log_metric_filter" "send_failures" {
  name           = "${local.function_name}-send-failures"
  log_group_name = aws_cloudwatch_log_group.careers_application.name
  pattern        = "?\"SES send failed\" ?\"unhandled error in lambda_handler\""

  metric_transformation {
    name      = "SendFailures"
    namespace = local.metric_namespace
    value     = "1"
    unit      = "Count"

    # Emit 0 on a non-matching event so the metric stays populated while the
    # form is working. Without it the alarm sits in INSUFFICIENT_DATA between
    # failures and never visibly returns to OK.
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "send_failures" {
  alarm_name        = "${local.function_name}-send-failures"
  alarm_description = "A careers application was accepted but could not be emailed to the hiring inbox (SES send failed, or the handler hit an unhandled error). The submission is lost — check /aws/lambda/${local.function_name}."

  namespace   = local.metric_namespace
  metric_name = aws_cloudwatch_log_metric_filter.send_failures.metric_transformation[0].name
  statistic   = "Sum"
  period      = 300

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.alarm_send_failure_threshold
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]
  ok_actions    = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]

  tags = local.tags
}

#
# The crash half. No min-request gate is needed here (unlike app-binbash-web's
# CloudFront *ErrorRate alarms, which are percentages that read ~100% on an idle
# site): Errors is a Sum of counts, so no traffic reports no errors rather than a
# false alarm.
#
resource "aws_cloudwatch_metric_alarm" "function_errors" {
  alarm_name        = "${local.function_name}-function-errors"
  alarm_description = "The careers-application Lambda failed to complete an invocation — timeout, out-of-memory, or a cold-start import failure. Distinct from ${local.function_name}-send-failures, which fires when the function ran and answered 500."

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  statistic   = "Sum"
  period      = 300
  dimensions = {
    FunctionName = aws_lambda_function.careers_application.function_name
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.alarm_function_error_threshold
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]
  ok_actions    = [data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring]

  tags = local.tags
}
