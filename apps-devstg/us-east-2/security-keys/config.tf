#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region_secondary
  profile = var.profile
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.2.7"

  required_providers {
    aws = "~> 5.0"
  }

  backend "s3" {
    key = "apps-devstg/security-keys-dr/terraform.tfstate"
  }
}
