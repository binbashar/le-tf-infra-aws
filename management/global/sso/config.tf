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
    aws = "~> 4.40"
  }

  backend "s3" {
    key = "root/sso/terraform.tfstate"
  }
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------
data "aws_ssoadmin_instances" "main" {}
