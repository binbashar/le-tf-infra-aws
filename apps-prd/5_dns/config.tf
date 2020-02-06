#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 2.46"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.20"

  backend "s3" {
    key = "apps-prd/dns/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for vpc
#
data "terraform_remote_state" "vpc-prd" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-shared-devops"
    bucket  = "bb-shared-terraform-backend"
    key     = "shared/dns/terraform.tfstate"
  }
}
