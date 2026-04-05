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
    aws = "~> 5.100"
  }

  backend "s3" {
    key = "data-science/airflow/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
# VPC Remote State
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "data-science/network/terraform.tfstate"
  }
}
