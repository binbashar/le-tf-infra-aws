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
  required_version = "~> 1.3.5"

  required_providers {
    aws = "~> 4.10"
  }

  backend "s3" {
    key = "shared/container-registry/terraform.tfstate"
  }
}
