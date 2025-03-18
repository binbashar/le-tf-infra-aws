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
  required_version = "~> 1.5.0"

  required_providers {
    aws = "~> 4.10"
  }

  backend "s3" {
    key = "apps-devstg/alb-logs-s3-bucket/terraform.tfstate"
  }
}
