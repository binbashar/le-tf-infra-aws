output "github_actions_opentofu_plan_role_arn" {
  description = "Role ARN to configure as the AWS_TOFU_PLAN_ROLE_ARN GitHub variable"
  value       = aws_iam_role.github_actions_opentofu_plan.arn
}

output "github_actions_opentofu_noop_role_arn" {
  description = "Role ARN for the supervised no-change plan verification only"
  value       = aws_iam_role.github_actions_opentofu_noop.arn
}

output "github_actions_opentofu_bedrock_role_arn" {
  description = "Role ARN to configure as the AWS_TOFU_PLAN_BEDROCK_ROLE_ARN GitHub variable"
  value       = aws_iam_role.github_actions_opentofu_bedrock.arn
}

output "github_oidc_provider_arn" {
  description = "Account-wide GitHub Actions OIDC provider owned by this layer"
  value       = aws_iam_openid_connect_provider.github.arn
}
