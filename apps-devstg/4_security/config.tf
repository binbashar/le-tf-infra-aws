#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
  version = ">= 2.40"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.18"

  backend "s3" {
    key = "dev/security/terraform.tfstate"
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
    bucket  = "bb-dev-terraform-state-storage-s3"
    key     = "dev/notifications/terraform.tfstate"
  }
}