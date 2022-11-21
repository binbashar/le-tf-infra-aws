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
  required_version = ">= 1.1.3"

  required_providers {
    aws = "~> 4.31.0"
  }

  backend "s3" {
    key = "root/security-monitoring-dr/terraform.tfstate"
  }
}
