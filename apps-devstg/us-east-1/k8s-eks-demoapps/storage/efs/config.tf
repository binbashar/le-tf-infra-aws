#
# AWS Provider Settings
#
provider "aws" {
  region  = var.region
  profile = var.profile
}

#
# Backend Config (partial)
#
terraform {
  required_version = "~> 1.2"

  required_providers {
    aws = "~> 4.11"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks-demoapps/storage/efs/terraform.tfstate"
  }
}

#
# Data sources
#
data "terraform_remote_state" "cluster-vpc" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/k8s-eks-demoapps/network/terraform.tfstate"
  }
}
