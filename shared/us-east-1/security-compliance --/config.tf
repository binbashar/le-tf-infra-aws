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
    aws = "~> 3.2"
  }

  backend "s3" {
    key = "shared/security-compliance/terraform.tfstate"
  }
}

#
# AWS Config primary region
#
data "terraform_remote_state" "security-security-compliance" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-security-devops"
    bucket  = "${var.project}-security-terraform-backend"
    key     = "security/security-compliance/terraform.tfstate"
  }
}
