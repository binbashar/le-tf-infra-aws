#
# Providers
#
# AWS
#
provider "aws" {
  version                 = "~> 2.46"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/config"
}

#
# Backend Config (partial)
#
terraform {
  required_version = ">= 0.12.24"

  backend "s3" {
    key = "apps-devstg/k8s-eks/prerequisites/terraform.tfstate"
  }
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for vpc
#
data "terraform_remote_state" "vpc-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-shared-devops"
    bucket  = "bb-shared-terraform-backend"
    key     = "shared/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-shared-devops"
    bucket  = "bb-shared-terraform-backend"
    key     = "shared/dns/terraform.tfstate"
  }
}
