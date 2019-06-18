# SNS topic arn
output "sns_topic_50_arn" {
  description = "The SNS Topic ARN to be subscribed in order to get the cloudwatch billing alerts"
  value       = "${module.aws_cost_mgmt_billing_alert_50.sns_topic_arn}"
}

output "sns_topic_100_arn" {
  description = "The SNS Topic ARN to be subscribed in order to get the cloudwatch billing alerts"
  value       = "${module.aws_cost_mgmt_billing_alert_100.sns_topic_arn}"
}
