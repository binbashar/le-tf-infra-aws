output "agent_role_arn" {
  description = "ARN of the FinOps Agent data-access role. Select this in wizard Step 2 (AWS resources access)."
  value       = aws_iam_role.agent.arn
}

output "operator_role_arn" {
  description = "ARN of the FinOps Agent operator role. Select this in wizard Step 3 (web app access)."
  value       = aws_iam_role.operator.arn
}
