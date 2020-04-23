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
    key = "shared/identities/terraform.tfstate"
  }
}
