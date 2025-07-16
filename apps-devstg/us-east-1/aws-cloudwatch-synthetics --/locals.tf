locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
  # network
  local-vpc = {
    local-base = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/network/terraform.tfstate"
    }
  }

}
