#=============================
# AWS Provider Settings
#=============================
provider "aws" {
  region  = var.region
  profile = var.profile
}

#=============================
# Backend Config (partial)
#=============================
terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = "~> 5.0"
  }

  backend "s3" {
    key = "data-science/workflow-order-processing/terraform.tfstate"
  }
}
