#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 2.59"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/bb-le/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.24"

  backend "s3" {
    key = "apps-prd/security/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for notifications
#
data "terraform_remote_state" "notifications" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/notifications/terraform.tfstate"
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-security-devops"
    bucket  = "bb-security-terraform-backend"
    key     = "security/security/terraform.tfstate"
  }
}
