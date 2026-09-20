output "github_actions_tofu_plan_role_arn" {
  description = "Role ARN to configure as the AWS_TOFU_PLAN_ROLE_ARN GitHub variable"
  value       = aws_iam_role.github_actions_plan.arn
}

output "github_oidc_provider_arn" {
  description = "Account-wide GitHub Actions OIDC provider owned by this layer"
  value       = aws_iam_openid_connect_provider.github.arn
}
