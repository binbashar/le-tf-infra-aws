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
  required_version = ">= 0.12.20"


  backend "s3" {
    key = "shared/vpn/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
variable "region_backend_data" {
  description = "AWS Region"
  default     = "us-east-1"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region_backend_data
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns" {
  backend = "s3"

  config = {
    region  = var.region_backend_data
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/dns/terraform.tfstate"
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    region  = var.region_backend_data
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security/terraform.tfstate"
  }
}
