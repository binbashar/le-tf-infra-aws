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
    aws = "~> 4.10"
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.24.0"
    }
  }

  backend "s3" {
    key = "apps-devstg/databases-aurora-pgsql/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "secrets" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/secrets-manager/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/k8s-eks/network/terraform.tfstate" # Use k8s-vpc to avoid network overlapping
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

data "terraform_remote_state" "datascience-vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-data-science-devops"
    bucket  = "${var.project}-data-science-terraform-backend"
    key     = "data-science/network/terraform.tfstate"
  }
}

