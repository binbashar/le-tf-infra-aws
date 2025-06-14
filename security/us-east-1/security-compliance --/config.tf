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
  required_version = "~> 1.6.0"

  required_providers {
    aws = "~> 3.2"
  }

  backend "s3" {
    key = "security/security-compliance/terraform.tfstate"
  }
}
