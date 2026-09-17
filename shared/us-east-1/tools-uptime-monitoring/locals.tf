locals {
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    "aws-apn-id" = local.prm_apn_id
  }
  # network
  local_vpc = {
    local-base = {
      region  = var.region
      profile = "${var.project}-shared-devops"
      bucket  = "${var.project}-shared-terraform-backend"
      key     = "shared/network/terraform.tfstate"
    }
  }

}
