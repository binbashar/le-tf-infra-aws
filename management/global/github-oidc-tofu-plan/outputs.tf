output "github_actions_opentofu_plan_role_arn" {
  description = "Role ARN to configure for the management account in the TOFU_PLAN_ROLES GitHub variable"
  value       = aws_iam_role.github_actions_opentofu_plan.arn
}

output "github_oidc_provider_arn" {
  description = "Account-wide GitHub Actions OIDC provider owned by this layer"
  value       = aws_iam_openid_connect_provider.github.arn
}
