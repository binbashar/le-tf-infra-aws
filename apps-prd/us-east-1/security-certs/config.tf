#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
  # comment this 2 lines for aws sso enable
  # shared_credentials_files = ["~/.aws/${var.project}/credentials"]
  # shared_config_files      = ["~/.aws/${var.project}/config"]
}

# Here we need a different AWS provider because ACM certificates
# DNS validation records needs to be created in binbash-shared account
#
# binbash-shared route53 cross-account ACM dns validation update
#
provider "aws" {
  region  = var.region
  profile = "${var.project}-shared-devops"
  # comment this 2 lines for aws sso enable
  # shared_credentials_files = ["~/.aws/${var.project}/credentials"]
  # shared_config_files      = ["~/.aws/${var.project}/config"]
  alias = "shared-route53"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = "~> 4.0"
  }

  backend "s3" {
    key = "apps-prd/security-certs/terraform.tfstate"
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
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/dns/binbash.com.ar/terraform.tfstate"
  }
}
