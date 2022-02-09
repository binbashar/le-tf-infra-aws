output "required_tags_rule_arn" {
  description = "S3 bucket containing AWS logs."
  value       = module.terraform-aws-config.required_tags_rule_arn
}
