output "s3_bucket" {
  description = "Name of the S3 origin bucket holding the static export (repo variable BINBASH_WEB_S3_BUCKET)"
  value       = module.binbash_web.s3_bucket
}

output "cf_distribution_id" {
  description = "CloudFront distribution ID, used by CI to create invalidations (repo variable BINBASH_WEB_CF_DISTRIBUTION_ID)"
  value       = module.binbash_web.cf_id
}

output "cf_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.binbash_web.cf_domain_name
}

output "app_fqdn" {
  description = "Public FQDN serving the app (staging)"
  value       = local.app_fqdn
}

output "deploy_role_arn" {
  description = "GitHub OIDC deploy role ARN, assumed by the app repo CI (repo variable BINBASH_WEB_AWS_DEPLOY_ROLE_ARN)"
  value       = aws_iam_role.github_actions_deploy.arn
}

#
# Staging access gate (removed at cutover — see staging.tf)
#
output "staging_basic_auth_username" {
  description = "Username for the staging HTTP Basic gate"
  value       = var.staging_basic_auth_username
}

output "staging_basic_auth_password" {
  description = "Password for the staging HTTP Basic gate. Read with `leverage tofu output -raw staging_basic_auth_password` — it is generated, never committed to this public repo."
  value       = random_password.staging_basic_auth.result
  sensitive   = true
}
