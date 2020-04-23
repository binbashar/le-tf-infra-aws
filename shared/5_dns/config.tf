#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 2.46"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.24"

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
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-devstg" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-apps-devstg-devops"
    bucket  = "bb-apps-devstg-terraform-backend"
    key     = "apps-devstg/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns-apps-devstg-kops" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-apps-devstg-devops"
    bucket  = "bb-apps-devstg-terraform-backend"
    key     = "apps-devstg/k8s-kops/prerequisites/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-devstg-eks" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-apps-devstg-devops"
    bucket  = "bb-apps-devstg-terraform-backend"
    key     = "apps-devstg/k8s-eks/prerequisites/terraform.tfstate"
  }
}

data "terraform_remote_state" "ec2-fleet-ansible" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-apps-devstg-devops"
    bucket  = "bb-apps-devstg-terraform-backend"
    key     = "apps-devstg/ec2-fleet-ansible/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-apps-prd" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-apps-prd-devops"
    bucket  = "bb-apps-prd-terraform-backend"
    key     = "apps-prd/network/terraform.tfstate"
  }
}

