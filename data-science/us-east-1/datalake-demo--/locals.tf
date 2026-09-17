locals {
  name = "${var.project}-${var.environment}-data-lake-demo"

  tags = {
    Name         = local.name
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }
}
