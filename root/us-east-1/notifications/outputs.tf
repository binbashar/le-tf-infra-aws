#=============================#
# Notifications Outputs       #
#=============================#
#
# AWS SNS -> Lambda -> Slack: tools-monitoring
#
output "sns_topic_arn_monitoring" {
  description = "ARN of the created SNS topic for Slack"
  value       = module.notify_slack_monitoring.this_slack_topic_arn
}

output "sns_topic_name_monitoring" {
  description = "Name of the created SNS topic for Slack"
  value       = var.sns_topic_name_monitoring
}

output "lambda_iam_role_arn_monitoring" {
  description = "The ARN of the IAM role used by Lambda function"
  value       = module.notify_slack_monitoring.lambda_iam_role_arn
}

output "lambda_iam_role_name_monitoring" {
  description = "The name of the IAM role used by Lambda function"
  value       = module.notify_slack_monitoring.lambda_iam_role_name
}

output "notify_slack_monitoring_lambda_function_arn_monitoring" {
  description = "The ARN of the Lambda function"
  value       = module.notify_slack_monitoring.notify_slack_lambda_function_arn
}

output "notify_slack_monitoring_lambda_function_invoke_arn_monitoring" {
  description = "The ARN to be used for invoking Lambda function from API Gateway"
  value       = module.notify_slack_monitoring.notify_slack_lambda_function_invoke_arn
}

output "notify_slack_monitoring_lambda_function_last_modified_monitoring" {
  description = "The date Lambda function was last modified"
  value       = module.notify_slack_monitoring.notify_slack_lambda_function_last_modified
}

output "notify_slack_monitoring_lambda_function_name_monitoring" {
  description = "The name of the Lambda function"
  value       = module.notify_slack_monitoring.notify_slack_lambda_function_name
}

output "notify_slack_monitoring_lambda_function_version_monitoring" {
  description = "TLatest published version of your Lambda function"
  value       = module.notify_slack_monitoring.notify_slack_lambda_function_version
}

#
# AWS SNS -> Lambda -> Slack: tools-monitoring-sec
#
output "sns_topic_arn_monitoring_sec" {
  description = "ARN of the created SNS topic for Slack"
  value       = module.notify_slack_monitoring_sec.this_slack_topic_arn
}

output "sns_topic_name_monitoring_sec" {
  description = "Name of the created SNS topic for Slack"
  value       = var.sns_topic_name_monitoring_sec
}

output "lambda_iam_role_arn_monitoring_sec" {
  description = "The ARN of the IAM role used by Lambda function"
  value       = module.notify_slack_monitoring_sec.lambda_iam_role_arn
}

output "lambda_iam_role_name_monitoring_sec" {
  description = "The name of the IAM role used by Lambda function"
  value       = module.notify_slack_monitoring_sec.lambda_iam_role_name
}

output "notify_slack_monitoring_sec_lambda_function_arn_monitoring_sec" {
  description = "The ARN of the Lambda function"
  value       = module.notify_slack_monitoring_sec.notify_slack_lambda_function_arn
}

output "notify_slack_monitoring_sec_lambda_function_invoke_arn_monitoring_sec" {
  description = "The ARN to be used for invoking Lambda function from API Gateway"
  value       = module.notify_slack_monitoring_sec.notify_slack_lambda_function_invoke_arn
}

output "notify_slack_monitoring_sec_lambda_function_last_modified_monitoring_sec" {
  description = "The date Lambda function was last modified"
  value       = module.notify_slack_monitoring_sec.notify_slack_lambda_function_last_modified
}

output "notify_slack_monitoring_sec_lambda_function_name_monitoring_sec" {
  description = "The name of the Lambda function"
  value       = module.notify_slack_monitoring_sec.notify_slack_lambda_function_name
}

output "notify_slack_monitoring_sec_lambda_function_version_monitoring_sec" {
  description = "TLatest published version of your Lambda function"
  value       = module.notify_slack_monitoring_sec.notify_slack_lambda_function_version
}

output "sns_topic_arn_sms" {
  description = "ARN for SMS SNS topic"
  value       = try(module.notify_sms.sns_topic[0]["arn"], null)
}
