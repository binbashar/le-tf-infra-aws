locals {
  tags = {
    Terraform           = "true"
    Environment         = var.environment
    ProtectFromDeletion = "true"
  }
}

locals {
  # Data source definitions
  #

  # shared-dr
  shared-dr-vpcs = {
    shared-base-dr = {
      region  = var.region
      profile = "${var.project}-shared-devops"
      bucket  = "${var.project}-shared-terraform-backend"
      key     = "shared/network-dr/terraform.tfstate"
    }
  }

  # network-dr
  network-dr-vpcs = {
    network-base-dr = {
      region  = var.region
      profile = "${var.project}-network-devops"
      bucket  = "${var.project}-network-terraform-backend"
      key     = "network/network-dr/terraform.tfstate"
    }
  }

  # apps-devstg-dr
  apps-devstg-dr-vpcs = {
    apps-devstg-k8s-eks-dr = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks-dr/network/terraform.tfstate"
    }
  }

  # apps-prd
  apps-prd-vpcs = {}

  datasources-vpcs = merge(
    data.terraform_remote_state.network-dr-vpcs,     # network-dr
    data.terraform_remote_state.shared-dr-vpcs,      # shared-dr
    data.terraform_remote_state.apps-devstg-dr-vpcs, # apps-devstg-dr-vpcs
    data.terraform_remote_state.apps-prd-vpcs-dr,    # apps-prd-dr-vpcs
  )
}
