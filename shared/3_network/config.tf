#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 2.46"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.20"

  backend "s3" {
    key = "shared/network/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for vpc
#
data "terraform_remote_state" "vpc-apps-dev" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-apps-devstg-devops"
    bucket  = "bb-apps-devstg-terraform-backend"
    key     = "apps-devstg/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-dev-eks" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-apps-devstg-devops"
    bucket  = "bb-apps-devstg-terraform-backend"
    key     = "apps-devstg/k8s-eks/prerequisites/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-prd" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-apps-prd-devops"
    bucket  = "bb-apps-prd-terraform-backend"
    key     = "apps-prd/network/terraform.tfstate"
  }
}
