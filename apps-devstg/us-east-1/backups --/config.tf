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
  required_version = "~> 1.6.0"

  required_providers {
    aws = "~> 4.10"
  }

  backend "s3" {
    key = "apps-devstg/backups/terraform.tfstate"
  }
}
