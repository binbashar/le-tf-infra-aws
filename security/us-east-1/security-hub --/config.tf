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
    aws = "~> 5.41"
  }

  backend "s3" {
    key = "security/security-hub/terraform.tfstate"
  }
}

data "aws_organizations_organization" "this" {}