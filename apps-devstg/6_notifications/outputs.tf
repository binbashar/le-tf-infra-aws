#=============================#
# Notifications Outputs       #
#=============================#
#
# AWS SNS -> Lambda -> Slack: bb-tools-monitoring
#
output "sns_topic_arn_bb_monitoring" {
  description = "ARN of the created SNS topic for Slack"
  value       = module.notify_slack_bb_monitoring.this_slack_topic_arn
}

output "sns_topic_name_bb_monitoring" {
  description = "Name of the created SNS topic for Slack"
  value       = var.sns_topic_name_bb_monitoring
}

output "lambda_iam_role_arn_bb_monitoring" {
  description = "The ARN of the IAM role used by Lambda function"
  value       = module.notify_slack_bb_monitoring.lambda_iam_role_arn
}

output "lambda_iam_role_name_bb_monitoring" {
  description = "The name of the IAM role used by Lambda function"
  value       = module.notify_slack_bb_monitoring.lambda_iam_role_name
}

output "notify_slack_bb_monitoring_lambda_function_arn_bb_monitoring" {
  description = "The ARN of the Lambda function"
  value       = module.notify_slack_bb_monitoring.notify_slack_lambda_function_arn
}

output "notify_slack_bb_monitoring_lambda_function_invoke_arn_bb_monitoring" {
  description = "The ARN to be used for invoking Lambda function from API Gateway"
  value       = module.notify_slack_bb_monitoring.notify_slack_lambda_function_invoke_arn
}

output "notify_slack_bb_monitoring_lambda_function_last_modified_bb_monitoring" {
  description = "The date Lambda function was last modified"
  value       = module.notify_slack_bb_monitoring.notify_slack_lambda_function_last_modified
}

output "notify_slack_bb_monitoring_lambda_function_name_bb_monitoring" {
  description = "The name of the Lambda function"
  value       = module.notify_slack_bb_monitoring.notify_slack_lambda_function_name
}

output "notify_slack_bb_monitoring_lambda_function_version_bb_monitoring" {
  description = "TLatest published version of your Lambda function"
  value       = module.notify_slack_bb_monitoring.notify_slack_lambda_function_version
}

#
# AWS SNS -> Lambda -> Slack: bb-tools-monitoring-sec
#
output "sns_topic_arn_bb_monitoring_sec" {
  description = "ARN of the created SNS topic for Slack"
  value       = module.notify_slack_bb_monitoring_sec.this_slack_topic_arn
}

output "sns_topic_name_bb_monitoring_sec" {
  description = "Name of the created SNS topic for Slack"
  value       = var.sns_topic_name_bb_monitoring_sec
}

output "lambda_iam_role_arn_bb_monitoring_sec" {
  description = "The ARN of the IAM role used by Lambda function"
  value       = module.notify_slack_bb_monitoring_sec.lambda_iam_role_arn
}

output "lambda_iam_role_name_bb_monitoring_sec" {
  description = "The name of the IAM role used by Lambda function"
  value       = module.notify_slack_bb_monitoring_sec.lambda_iam_role_name
}

output "notify_slack_bb_monitoring_sec_lambda_function_arn_bb_monitoring_sec" {
  description = "The ARN of the Lambda function"
  value       = module.notify_slack_bb_monitoring_sec.notify_slack_lambda_function_arn
}

output "notify_slack_bb_monitoring_sec_lambda_function_invoke_arn_bb_monitoring_sec" {
  description = "The ARN to be used for invoking Lambda function from API Gateway"
  value       = module.notify_slack_bb_monitoring_sec.notify_slack_lambda_function_invoke_arn
}

output "notify_slack_bb_monitoring_sec_lambda_function_last_modified_bb_monitoring_sec" {
  description = "The date Lambda function was last modified"
  value       = module.notify_slack_bb_monitoring_sec.notify_slack_lambda_function_last_modified
}

output "notify_slack_bb_monitoring_sec_lambda_function_name_bb_monitoring_sec" {
  description = "The name of the Lambda function"
  value       = module.notify_slack_bb_monitoring_sec.notify_slack_lambda_function_name
}

output "notify_slack_bb_monitoring_sec_lambda_function_version_bb_monitoring_sec" {
  description = "TLatest published version of your Lambda function"
  value       = module.notify_slack_bb_monitoring_sec.notify_slack_lambda_function_version
}
