#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
  version = ">= 2.38"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.18"

  backend "s3" {
    key = "shared/dns/terraform.tfstate"
  }
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
    profile = var.profile
    bucket  = "bb-shared-terraform-state-storage-s3"
    key     = "shared/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-dev" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-dev-devops"
    bucket  = "bb-dev-terraform-state-storage-s3"
    key     = "dev/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns-dev-kops" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-dev-devops"
    bucket  = "bb-dev-terraform-state-storage-s3"
    key     = "dev/k8s-kops/prerequisites/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-dev-eks" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-dev-devops"
    bucket  = "bb-dev-terraform-state-storage-s3"
    key     = "dev/k8s-eks/prerequisites/terraform.tfstate"
  }
}
