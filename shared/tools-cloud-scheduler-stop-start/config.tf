#
# Providers
#
provider "aws" {
  version                 = "~> 2.63"
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
    key = "shared/cloud-scheduler-stop-start/terraform.tfstate"
  }
}
