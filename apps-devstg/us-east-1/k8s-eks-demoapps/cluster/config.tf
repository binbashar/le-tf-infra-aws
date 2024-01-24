#
# Providers
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
    aws        = "~> 5.24"
    kubernetes = "~> 2.23"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks-demoapps/cluster/terraform.tfstate"
  }
}

#
# Data Sources
#


data "terraform_remote_state" "cluster-vpc" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "cluster-identities" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/k8s-eks-demoapps/identities/terraform.tfstate"
  }
}

data "terraform_remote_state" "keys" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/security-keys/terraform.tfstate"
  }
}

data "terraform_remote_state" "shared-vpc" {
  backend = "s3"
  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/network/terraform.tfstate"
  }
}
