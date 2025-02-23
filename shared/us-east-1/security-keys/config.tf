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
  required_version = ">= 1.2"

  required_providers {
    aws = "~> 5.0"
  }

  backend "s3" {
    key = "shared/security-keys/terraform.tfstate"
  }
}
