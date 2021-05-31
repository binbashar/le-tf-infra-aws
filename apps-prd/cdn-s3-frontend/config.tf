#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
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
  region                  = var.region
  profile                 = var.profile_shared
  shared_credentials_file = "~/.aws/${var.project}/config"
  alias                   = "shared-route53"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.13.2"

  required_providers {
    aws = "~> 3.0"
  }

  backend "s3" {
    key = "apps-prd/cdn-s3/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for security certs
#
data "terraform_remote_state" "certificates" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-certs/terraform.tfstate"
  }
}

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
