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
  required_version = "~> 1.2.7"

  required_providers {
    aws = "~> 4.10"
  }

  backend "s3" {
    key = "apps-devstg/security-keys/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "security-identities" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-security-devops"
    bucket  = "${var.project}-security-terraform-backend"
    key     = "security/identities/terraform.tfstate"
  }
}
