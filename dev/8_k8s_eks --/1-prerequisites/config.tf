#
# Providers
#
# AWS
#
provider "aws" {
  region  = var.region
  profile = var.profile
  version = ">= 2.40"
}

#
# Backend Config (partial)
#
terraform {
  required_version = ">= 0.12.19"

  backend "s3" {
    key = "dev/k8s-eks/prerequisites/terraform.tfstate"
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
    bucket  = "bb-shared-terraform-state-storage-s3"
    key     = "shared/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-shared-devops"
    bucket  = "bb-shared-terraform-state-storage-s3"
    key     = "shared/dns/terraform.tfstate"
  }
}
