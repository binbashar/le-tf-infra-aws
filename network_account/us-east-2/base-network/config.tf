#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region_secondary
  profile = var.profile
}

provider "aws" {
  alias   = "network"
  region  = var.region_secondary
  profile = var.profile
}

provider "aws" {
  alias   = "shared"
  region  = var.region_secondary
  profile = "${var.project}-shared-devops"
}

provider "aws" {
  alias   = "apps-devstg"
  region  = var.region_secondary
  profile = "${var.project}-apps-devstg-devops"
}

provider "aws" {
  alias   = "apps-prd"
  region  = var.region_secondary
  profile = "${var.project}-apps-prd-devops"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 4.10"
  }

  backend "s3" {
    key = "network/network-dr/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

data "aws_caller_identity" "current" {}

# TGW
data "terraform_remote_state" "tgw-dr" {
  count = var.enable_tgw ? 1 : 0

  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-network-devops"
    bucket  = "${var.project}-network-terraform-backend"
    key     = "network/transit-gateway-dr/terraform.tfstate"
  }
}

# VPC remote states for network-dr
data "terraform_remote_state" "network-dr-vpcs" {
  for_each = var.enable_network_firewall ? local.network-dr-vpcs : {}

  backend = "s3"

  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }

}

# VPC remote states for shared-dr
data "terraform_remote_state" "shared-dr-vpcs" {

  for_each = local.shared-dr-vpcs

  backend = "s3"

  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

# VPC remote states for apps-devstg-dr
data "terraform_remote_state" "apps-devstg-dr-vpcs" {

  for_each = local.apps-devstg-dr-vpcs

  backend = "s3"

  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

# VPC remote states for apps-prd-dr
data "terraform_remote_state" "apps-prd-dr-vpcs" {

  for_each = local.apps-prd-dr-vpcs

  backend = "s3"

  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}
