#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.14.11"

  required_providers {
    aws = "~> 3.27"
  }

  backend "s3" {
    key = "shared/k8s-eks-demoapps/identities/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "dns" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/dns/binbash.com.ar/terraform.tfstate"
  }
}

data "terraform_remote_state" "apps-devstg-eks-demoapps-cluster" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/k8s-eks-demoapps/cluster/terraform.tfstate"
  }
}
