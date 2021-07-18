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
  required_version = ">= 0.14.11"

  required_providers {
    aws = "~> 3.0"
  }

  backend "s3" {
    key = "network/inspection-network/terraform.tfstate"
  }
}

data "terraform_remote_state" "network-firewall" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-network-devops"
    bucket  = "${var.project}-network-terraform-backend"
    key     = "network/network-firewall/terraform.tfstate"

  }
}
