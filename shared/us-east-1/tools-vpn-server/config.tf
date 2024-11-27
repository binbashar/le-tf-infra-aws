#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.2"

  required_providers {
    aws = "~> 4.0"
  }

  backend "s3" {
    key = "shared/vpn-server/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config  = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-dr" {
  backend = "s3"
  config  = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network-dr/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns" {
  backend = "s3"
  config  = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/dns/binbash.com.ar/terraform.tfstate"
  }
}

data "terraform_remote_state" "keys" {
  backend = "s3"
  config  = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}
