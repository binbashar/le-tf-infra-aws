locals {
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }

  # The DNS account's profile and backend bucket, as Leverage configures them
  dns_backend   = file("${path.module}/../../../${var.dns_account}/config/backend.tfvars")
  dns_profile   = regex("(?m)^\\s*profile\\s*=\\s*\"([^\"]+)\"", local.dns_backend)[0]
  dns_bucket    = regex("(?m)^\\s*bucket\\s*=\\s*\"([^\"]+)\"", local.dns_backend)[0]
  dns_state_key = var.dns_state_key != "" ? var.dns_state_key : "${var.dns_account}/dns/${var.ses_domain}/terraform.tfstate"
}
