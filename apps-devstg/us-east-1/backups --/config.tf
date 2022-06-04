#
# Providers
#
provider "aws" {
  region  = var.region
  profile = var.profile
}

#
# Backend Config (partial)
#
terraform {
  required_version = "~> 1.1.3"

  required_providers {
    aws = "~> 4.0"
  }


  backend "s3" {
    key = "apps-devstg/backups/terraform.tfstate"
  }
}
