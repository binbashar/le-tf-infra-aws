locals {
  environment = replace(var.environment, "-", "")
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }
}
