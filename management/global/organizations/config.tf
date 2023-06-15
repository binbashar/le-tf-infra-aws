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
  required_version = "~> 1.2"

  required_providers {
    aws = "~> 4.0"
  }

  backend "s3" {
    key = "root/organizations/terraform.tfstate"
  }
}
