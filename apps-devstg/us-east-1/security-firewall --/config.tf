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
    aws = "~> 4.10.0"
  }

  backend "s3" {
    key = "apps-devstg/security-firewall/terraform.tfstate"
  }
}
