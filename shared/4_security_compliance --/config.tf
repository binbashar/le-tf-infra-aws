#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
  shared_credentials_file = "~/.aws/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.17"

  backend "s3" {
    key = "dev/securitycompliance/terraform.tfstate"
  }
}

variable "bucket_region" {
  description = "AWS Region"
  default     = "us-east-1"
}