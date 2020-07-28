module "kms_key" {
  source = "github.com/binbashar/terraform-aws-kms-key.git?ref=0.4.0"

  enabled                 = true
  namespace               = var.project
  stage                   = var.environment
  name                    = var.kms_key_name
  delimiter               = "-"
  description             = "KMS key for ${var.project}-${var.environment} Account"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  alias                   = "alias/${var.project}_${var.environment}_${var.kms_key_name}_key"
  tags                    = local.tags
}
