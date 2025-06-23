#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region_secondary
  profile = var.profile
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 3.2"
  }

  backend "s3" {
    key = "network/security-compliance-dr/terraform.tfstate"
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
