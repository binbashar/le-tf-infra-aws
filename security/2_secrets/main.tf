#
# Vault
#
resource "aws_ssm_parameter" "your_secret_name" {
  name        = "/vault/${var.environment}/your_secret_name"
  description = "Your secret description here"
  type        = "SecureString"
  value       = "${var.your_secret_var}"
  tags        = "${local.tags}"
}
