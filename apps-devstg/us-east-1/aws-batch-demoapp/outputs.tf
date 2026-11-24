#=============================#
# Compute environment         #
#=============================#
output "compute_type" {
  description = "Backend of the compute environment (FARGATE, FARGATE_SPOT, EC2 or SPOT)"
  value       = var.compute_type
}

output "compute_environment_arn" {
  description = "ARN of the AWS Batch compute environment"
  value       = module.batch.compute_environments["main"].arn
}

output "compute_environment_name" {
  description = "Name of the AWS Batch compute environment"
  value       = module.batch.compute_environments["main"].name
}

output "security_group_id" {
  description = "Security group of the compute environment (allow it on the resources the jobs must reach)"
  value       = aws_security_group.batch.id
}

output "launch_template_id" {
  description = "Launch template of the EC2 container instances (null for Fargate)"
  value       = try(aws_launch_template.batch[0].id, null)
}

output "instance_iam_role_arn" {
  description = "IAM role of the EC2 container instances (null for Fargate)"
  value       = module.batch.instance_iam_role_arn
}

#=============================#
# Job queue and definitions   #
#=============================#
output "job_queue_arn" {
  description = "ARN of the AWS Batch job queue"
  value       = module.batch.job_queues["main"].arn
}

output "job_queue_name" {
  description = "Name of the AWS Batch job queue"
  value       = module.batch.job_queues["main"].name
}

output "job_definitions" {
  description = "Job definitions created by this layer: key => { name, arn, revision }"
  value = {
    for k, v in module.batch.job_definitions : k => {
      name     = v.name
      arn      = v.arn
      revision = v.revision
    }
  }
}

#=============================#
# IAM                         #
#=============================#
output "execution_role_arn" {
  description = "Execution role (image pull, logs, secrets)"
  value       = aws_iam_role.execution.arn
}

output "job_role_arn" {
  description = "Job role (permissions of the job's code)"
  value       = aws_iam_role.job.arn
}

#=============================#
# Logs, schedules, alerts     #
#=============================#
output "log_group_name" {
  description = "CloudWatch log group with the jobs' output"
  value       = aws_cloudwatch_log_group.jobs.name
}

output "schedule_arns" {
  description = "EventBridge Scheduler schedules that submit jobs"
  value       = module.eventbridge.eventbridge_schedule_arns
}

output "scheduler_role_arn" {
  description = "IAM role assumed by EventBridge Scheduler to submit jobs"
  value       = module.eventbridge.eventbridge_role_arn
}

output "failure_notifications_rule_arns" {
  description = "EventBridge rule that sends job state changes to Slack"
  value       = module.eventbridge.eventbridge_rule_arns
}

output "failure_notifications_sns_topic_arn" {
  description = "SNS topic receiving the job state change notifications"
  value       = local.failure_notifications_sns_topic_arn
}
