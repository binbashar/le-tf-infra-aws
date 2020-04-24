#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 2.59"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/bb-le/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.24"

  backend "s3" {
    key = "apps-devstg/securitycompliance/terraform.tfstate"
  }
}

variable "bucket_region" {
  description = "AWS Region"
  default     = "us-east-1"
}
