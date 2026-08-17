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
  description = "Public FQDN serving the app"
  value       = local.app_fqdn
}

output "verification_url" {
  description = "Hit this to verify the site before the DNS cutover — the distribution's own domain, which works regardless of where binbash.co points"
  value       = "https://${module.binbash_web.cf_domain_name}/"
}

output "deploy_role_arn" {
  description = "GitHub OIDC deploy role ARN, assumed by the app repo CI (repo variable BINBASH_WEB_AWS_DEPLOY_ROLE_ARN)"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "redirect_count" {
  description = "Number of Wix->binbash-web 301 redirects served by the CloudFront Function (see redirects.tf)"
  value       = length(local.wix_redirects)
}
