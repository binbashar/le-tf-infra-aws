#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#
# Terraform aws provider to create the user in security
# NOTE: The rest of the resources will remain in the current account
#
provider "aws" {
  alias                   = "security"
  region                  = var.region
  profile                 = "${var.project}-security-devops"
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#
# Here we need a different AWS provider because Route53 records need to be
# created in binbash-shared account
#
provider "aws" {
  alias                     = "shared-route53"
  region                    = var.region
  profile                   = "${var.project}-shared-devops"
  shared_credentials_file   = "~/.aws/${var.project}/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.0.9"

  required_providers {
    aws = "~> 3.2"
  }

  backend "s3" {
    key = "apps-devstg/storage-s3-bucket-hipaa/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "shared-dns" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "shared/dns/binbash.com.ar/terraform.tfstate"
  }
}

data "terraform_remote_state" "apps-devstg-storage-s3-bucket" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${environment}/storage-s3-bucket-hipaa/terraform.tfstate"
  }
}
