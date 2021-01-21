#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.14.4"

  required_providers {
    aws = "~> 3.2"
  }

  backend "s3" {
    key = "apps-devstg/network/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for vpc
#
data "terraform_remote_state" "vpc-eks" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/k8s-eks/network/terraform.tfstate"
  }
}

#
# data type from output for notifications
#
data "terraform_remote_state" "notifications" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/notifications/terraform.tfstate"
  }
}

#
# data type from output for vpc
#
data "terraform_remote_state" "vpc-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/network/terraform.tfstate"
  }
}

#
# data type from output for tools-ec2
#
data "terraform_remote_state" "tools-vpn-server" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/vpn/terraform.tfstate"
  }
}
