locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  # Data source definitions
  data_vpcs = {
    vpc-shared = {
      region  = var.region
      profile = "${var.project}-shared-devops"
      bucket  = "${var.project}-shared-terraform-backend"
      key     = "shared/shared/terraform.tfstate"
    }
    vpc-apps-prd = {
      region  = var.region
      profile = "${var.project}-apps-prd-devops"
      bucket  = "${var.project}-apps-prd-terraform-backend"
      key     = "apps-prd/network/terraform.tfstate"
    }
  }
}
