#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region                  = var.region_secondary
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.0.9"

  required_providers {
    aws = "~> 3.2"
  }

  backend "s3" {
    key = "network/security-keys-dr/terraform.tfstate"
  }
}
