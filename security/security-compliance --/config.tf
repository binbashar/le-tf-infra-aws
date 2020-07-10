#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 2.69"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.28"

  backend "s3" {
    key = "security/securitycompliance/terraform.tfstate"
  }
}

variable "bucket_region" {
  description = "AWS Region"
  default     = "us-east-1"
}
