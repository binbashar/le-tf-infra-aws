#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "management"
  region  = var.region
  profile = "${var.project}-root-administrator"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = "~> 5.0"
  }

  backend "s3" {
    key = "network/client-vpn/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

data "terraform_remote_state" "keys" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "network/security-keys/terraform.tfstate"
  }
}

data "terraform_remote_state" "certs" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "network/security-certs/terraform.tfstate"
  }
}

data "terraform_remote_state" "network_vpcs" {
  for_each = local.network_vpcs

  backend = "s3"
  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

data "terraform_remote_state" "apps_devstg_vpcs" {
  for_each = local.apps_devstg_vpcs

  backend = "s3"
  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

data "terraform_remote_state" "apps_prd_vpcs" {
  for_each = local.apps_prd_vpcs

  backend = "s3"
  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}