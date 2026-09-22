locals {
  # This intentionally minimal layer is the selected target for the read-only CI plan probe (concurrency probe 2).
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }
}
