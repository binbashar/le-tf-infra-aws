#
# EC2 aws_key_pair name
#
output "aws_key_pair_name" {
  value = aws_key_pair.compute-ssh-key.key_name
}

#
# KMS aws_kms_key outputs
#
output "aws_kms_key_arn" {
  description = "Key ARN"
  value = module.kms_key.key_arn
}

output "aws_kms_key_id" {
  description = "KMS Key ID"
  value = module.kms_key.key_id
}

output "aws_kms_key_alias_arn" {
  description = "KMS Alias ARN"
  value = module.kms_key.alias_arn
}

output "aws_kms_key_alias_name" {
  description = "KMS Alias name"
  value = module.kms_key.alias_name
}
