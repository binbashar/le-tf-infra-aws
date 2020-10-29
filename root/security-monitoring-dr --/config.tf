#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 3.0"
  region                  = var.region_secondary
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.28"

  backend "s3" {
    key = "root/security-monitoring-dr/terraform.tfstate"
  }
}
