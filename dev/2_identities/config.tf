#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
  version = ">= 2.40"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.18"

  backend "s3" {
    key = "dev/identities/terraform.tfstate"
  }
}
