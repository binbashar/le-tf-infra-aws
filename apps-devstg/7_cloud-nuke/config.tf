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
  required_version = ">= 0.12.19"

  backend "s3" {
    key = "dev/cloud-nuke/terraform.tfstate"
  }
}
