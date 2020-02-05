#
# Providers
#
provider "aws" {
  version                 = "~> 2.46"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/config"
}

#
# Backend Config (partial)
#
terraform {
  required_version = ">= 0.12.20"

  backend "s3" {
    key = "apps-prd/backups/terraform.tfstate"
  }
}
