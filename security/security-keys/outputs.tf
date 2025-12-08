#
# KMS aws_kms_key outputs
#
output "aws_kms_key_arn" {
  description = "Key ARN per region"
  value       = { for region, kms in module.kms_key : region => kms.key_arn }
}

output "aws_kms_key_id" {
  description = "KMS Key ID per region"
  value       = { for region, kms in module.kms_key : region => kms.key_id }
}

output "aws_kms_key_alias_arn" {
  description = "KMS Alias ARN per region"
  value       = { for region, kms in module.kms_key : region => kms.alias_arn }
}

output "aws_kms_key_alias_name" {
  description = "KMS Alias name per region"
  value       = { for region, kms in module.kms_key : region => kms.alias_name }
}
