#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "network"
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "shared"
  region  = var.region
  profile = "${var.project}-shared-devops"
}

provider "aws" {
  alias   = "apps-devstg"
  region  = var.region
  profile = "${var.project}-apps-devstg-devops"
}

provider "aws" {
  alias   = "apps-prd"
  region  = var.region
  profile = "${var.project}-apps-prd-devops"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 3.0"
  }

  backend "s3" {
    key = "network/network/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

data "aws_caller_identity" "current" {}

# TGW
data "terraform_remote_state" "tgw" {
  count = var.enable_tgw ? 1 : 0

  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-network-devops"
    bucket  = "${var.project}-network-terraform-backend"
    key     = "network/transit-gateway/terraform.tfstate"
  }
}

#
# data type from output for tools-ec2
#
data "terraform_remote_state" "tools-vpn-server" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/vpn-server/terraform.tfstate"
  }
}

data "terraform_remote_state" "network-firewall" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-network-devops"
    bucket  = "${var.project}-network-terraform-backend"
    key     = "network/network-firewall/terraform.tfstate"
  }
}

# VPC remote states for network
data "terraform_remote_state" "network-vpcs" {
  for_each = var.enable_network_firewall ? local.network-vpcs : {}

  backend = "s3"

  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }

}

# VPC remote states for shared
data "terraform_remote_state" "shared-vpcs" {

  for_each = local.shared-vpcs

  backend = "s3"

  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

# VPC remote states for apps-devstg
data "terraform_remote_state" "apps-devstg-vpcs" {

  for_each = local.apps-devstg-vpcs

  backend = "s3"

  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

# VPC remote states for apps-prd
data "terraform_remote_state" "apps-prd-vpcs" {

  for_each = local.apps-prd-vpcs

  backend = "s3"

  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}
