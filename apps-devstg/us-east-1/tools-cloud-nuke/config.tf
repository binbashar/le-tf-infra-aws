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
  required_version = ">= 0.14.11"

  required_providers {
    aws = "~> 3.0"
  }

  backend "s3" {
    key = "apps-devstg/cloud-nuke/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for security
#
data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}
