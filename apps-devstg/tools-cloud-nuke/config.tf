#
# Providers
#
provider "aws" {
  version                 = "~> 2.69"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/bb-le/config"
}

#
# Backend Config (partial)
#
terraform {
  required_version = ">= 0.12.28"

  backend "s3" {
    key = "apps-devstg/cloud-nuke/terraform.tfstate"
  }
}
