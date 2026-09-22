locals {
  # This intentionally minimal layer is the selected target for the read-only CI plan probe.
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }
}

# Temporary Gate 5 probe: static validation must reject this before live planning.
locals {
  poc_validation_probe = local.poc_undefined_local
}
