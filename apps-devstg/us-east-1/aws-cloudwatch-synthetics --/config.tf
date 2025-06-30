#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 4.0"
  }

  backend "s3" {
    key = "apps-devstg/aws-cloudwatch-synthetics/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

# VPC remote states for this account
data "terraform_remote_state" "local-vpcs" {

  backend = "s3"

  config = {
    region  = lookup(local.local-vpc.local-base, "region")
    profile = lookup(local.local-vpc.local-base, "profile")
    bucket  = lookup(local.local-vpc.local-base, "bucket")
    key     = lookup(local.local-vpc.local-base, "key")
  }
}


data "terraform_remote_state" "notifications" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/notifications/terraform.tfstate"
  }
}
