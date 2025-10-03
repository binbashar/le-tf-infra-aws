locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
  # network
  local-vpc = {
    local-base = {
      region  = var.region
      profile = "${var.project}-shared-devops"
      bucket  = "${var.project}-shared-terraform-backend"
      key     = "shared/network/terraform.tfstate"
    }
  }

}
