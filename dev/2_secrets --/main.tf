#
# Vault
#
resource "aws_ssm_parameter" "vault_unseal_key_1" {
  name        = "/vault/${var.environment}/unseal_key_1"
  description = "Vault Unseal Key 1"
  type        = "SecureString"
  value       = var.vault_unseal_key_1
  tags        = local.tags
}

resource "aws_ssm_parameter" "vault_unseal_key_2" {
  name        = "/vault/${var.environment}/unseal_key_2"
  description = "Vault Unseal Key 2"
  type        = "SecureString"
  value       = var.vault_unseal_key_2
  tags        = local.tags
}

resource "aws_ssm_parameter" "vault_unseal_key_3" {
  name        = "/vault/${var.environment}/unseal_key_3"
  description = "Vault Unseal Key 3"
  type        = "SecureString"
  value       = var.vault_unseal_key_3
  tags        = local.tags
}
