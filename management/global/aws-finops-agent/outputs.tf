output "agent_role_arn" {
  description = "ARN of the FinOps Agent data-access role. Select this in wizard Step 2 (AWS resources access)."
  value       = aws_iam_role.agent.arn
}

output "operator_role_arn" {
  description = "ARN of the FinOps Agent operator role. Select this in wizard Step 3 (web app access)."
  value       = aws_iam_role.operator.arn
}

output "anomaly_monitor_arn" {
  description = "ARN of the Cost Anomaly Detection monitor the agent investigates."
  value       = aws_ce_anomaly_monitor.service.arn
}

output "compute_optimizer_status" {
  description = "Compute Optimizer enrollment status for the management account."
  value       = var.enable_compute_optimizer ? aws_computeoptimizer_enrollment_status.this[0].status : "Inactive (not managed by this layer)"
}
