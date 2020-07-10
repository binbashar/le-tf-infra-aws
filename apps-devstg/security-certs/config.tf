#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 2.69"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

# Here we need a different AWS provider because ACM certificates
# DNS validation records needs to be created in binbash-shared account
#
# binbash-shared route53 cross-account ACM dns validation update
#
provider "aws" {
  version                 = "~> 2.69"
  region                  = var.region
  profile                 = var.profile_shared
  shared_credentials_file = "~/.aws/${var.project}/config"
  alias                   = "shared-route53"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.12.28"

  backend "s3" {
    key = "apps-devstg/securitycerts/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for dns
#
data "terraform_remote_state" "dns-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-shared-devops"
    bucket  = "bb-shared-terraform-backend"
    key     = "shared/dns/terraform.tfstate"
  }
}
