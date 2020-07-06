#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 2.56"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/bb-le/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.28"

  backend "s3" {
    key = "shared/eskibana/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/dns/terraform.tfstate"
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-devstg" {
  backend = "s3"
  config = {
    region  = var.region
    profile = "bb-apps-devstg-devops"
    bucket  = "bb-apps-devstg-terraform-backend"
    key     = "apps-devstg/network/terraform.tfstate"
  }
}