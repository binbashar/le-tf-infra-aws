locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  ram_principals = [var.shared_account_id, var.appsdevstg_account_id, var.appsprd_account_id]

  #
  # Data source definitions
  #

  # shared
  shared-vpcs = {
    shared = {
      region  = var.region
      profile = "${var.project}-shared-devops"
      bucket  = "${var.project}-shared-terraform-backend"
      key     = "shared/network/terraform.tfstate"
    }
  }

  # network
  network-vpcs = {
    base = {
      region  = var.region
      profile = "${var.project}-network-devops"
      bucket  = "${var.project}-network-terraform-backend"
      key     = "network/network/terraform.tfstate"
    }
  }

  # apps-devstg
  apps-devstg-vpcs = {
    base = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/network/terraform.tfstate"
    }
    k8s-eks = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks/network/terraform.tfstate"
    }
    eks-demoapps = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
    }
  }

  # apps-prd
  apps-prd-vpcs = {
    base = {
      region  = var.region
      profile = "${var.project}-apps-prd-devops"
      bucket  = "${var.project}-apps-prd-terraform-backend"
      key     = "apps-prd/network/terraform.tfstate"
    }
  }

}
