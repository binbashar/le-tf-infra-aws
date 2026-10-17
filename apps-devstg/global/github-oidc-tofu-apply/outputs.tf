output "github_actions_opentofu_apply_role_arn" {
  description = "Role ARN to configure for apps-devstg in the TOFU_APPLY_ROLES GitHub variable"
  value       = aws_iam_role.github_actions_opentofu_apply.arn
}

output "github_actions_opentofu_apply_boundary_arn" {
  description = "Permissions boundary attached to the apply role"
  value       = aws_iam_policy.github_actions_opentofu_apply_boundary.arn
}
