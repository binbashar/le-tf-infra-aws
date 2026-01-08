#=============================#
# MWAA Execution Role Outputs #
#=============================#
output "mwaa_execution_role_arn" {
  description = "IAM Role ARN for MWAA execution"
  value       = module.iam_assumable_role_mwaa_execution.iam_role_arn
}

output "mwaa_execution_role_name" {
  description = "IAM Role Name for MWAA execution"
  value       = module.iam_assumable_role_mwaa_execution.iam_role_name
}

#=============================#
# EventBridge Scheduler Outputs#
#=============================#
output "scheduler_arns" {
  description = "Map of EventBridge Scheduler ARNs"
  value = {
    for k, v in aws_scheduler_schedule.mwaa_create_environment : k => v.arn
  }
}

output "scheduler_role_arn" {
  description = "IAM Role ARN for EventBridge Scheduler to create MWAA environments"
  value       = try(aws_iam_role.scheduler[0].arn, null)
}

output "scheduler_role_name" {
  description = "IAM Role Name for EventBridge Scheduler"
  value       = try(aws_iam_role.scheduler[0].name, null)
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group for Scheduler logs"
  value       = aws_cloudwatch_log_group.scheduler_logs.name
}

output "enabled_schedules" {
  description = "List of enabled schedule names"
  value = [
    for k, v in var.schedules : k if v.enabled
  ]
}

output "mwaa_environment_name" {
  description = "MWAA environment name that will be created (project-environment-airflow)"
  value       = "${var.project}-${var.environment}-airflow"
}
