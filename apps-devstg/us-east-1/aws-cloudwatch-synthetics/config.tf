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
  required_version = "~> 1.2"

  required_providers {
    aws = "~> 4.10"
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

