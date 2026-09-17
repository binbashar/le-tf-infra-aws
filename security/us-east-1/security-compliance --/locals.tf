#================================#
# Local variables                #
#================================#
locals {
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }

  # If inspector is enabled these should be set
  inspector_members = ["shared", "apps-devstg"]
}
