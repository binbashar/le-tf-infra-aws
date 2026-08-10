output "s3_bucket" {
  description = "Name of the S3 origin bucket holding the static export"
  value       = module.aws_startups_accelerate.s3_bucket
}

output "cf_distribution_id" {
  description = "CloudFront distribution ID (used by CI to create invalidations)"
  value       = module.aws_startups_accelerate.cf_id
}

output "cf_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.aws_startups_accelerate.cf_domain_name
}

output "app_fqdn" {
  description = "Public FQDN serving the app"
  value       = local.app_fqdn
}

output "deploy_role_arn" {
  description = "GitHub OIDC deploy role ARN (assumed by the app repo CI)"
  value       = aws_iam_role.github_actions_deploy.arn
}
