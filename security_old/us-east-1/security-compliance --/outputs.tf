output "aws_logs_bucket" {
  description = "S3 bucket containing AWS logs."
  value       = module.config_logs.aws_logs_bucket
}

output "configs_logs_path" {
  description = "S3 path for Config logs."
  value       = module.config_logs.configs_logs_path
}

output "required_tags_rule_arn" {
  description = "S3 bucket containing AWS logs."
  value       = module.terraform-aws-config.required_tags_rule_arn
}
