#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
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
    key = "shared/k8s-eks-prd/identities/terraform.tfstate"
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

data "terraform_remote_state" "apps-prd-eks-cluster" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-prd-devops"
    bucket  = "${var.project}-apps-prd-terraform-backend"
    key     = "apps-prd/k8s-eks/cluster/terraform.tfstate"
  }
}
