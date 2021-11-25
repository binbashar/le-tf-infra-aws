#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region                  = var.region_secondary
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "network"
  region                  = var.region_secondary
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "shared"
  region                  = var.region_secondary
  profile                 = "${var.project}-shared-devops"
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "apps-devstg"
  region                  = var.region_secondary
  profile                 = "${var.project}-apps-devstg-devops"
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "apps-prd"
  region                  = var.region_secondary
  profile                 = "${var.project}-apps-prd-devops"
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.0.9"

  required_providers {
    aws = "~> 3.0"
  }

  backend "s3" {
    key = "network/network-dr/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

data "aws_caller_identity" "current" {}

#
# data type from output for tools-ec2
#
#data "terraform_remote_state" "tools-vpn-server-dr" {
#  backend = "s3"
#
#  config = {
#    region  = var.region
#    profile = "${var.project}-shared-devops"
#    bucket  = "${var.project}-shared-terraform-backend"
#    key     = "shared/vpn-dr/terraform.tfstate"
#  }
#}

#data "terraform_remote_state" "tgw-dr" {
#  backend = "s3"
#
#  config = {
#    region  = var.region
#    profile = "${var.project}-network-devops"
#    bucket  = "${var.project}-network-terraform-backend"
#    key     = "network/transit-gateway-dr/terraform.tfstate"
#  }
#}


#data "terraform_remote_state" "network-firewall-dr" {
#  backend = "s3"
#
#  config = {
#    region  = var.region
#    profile = "${var.project}-network-devops"
#    bucket  = "${var.project}-network-terraform-backend"
#    key     = "network/network-firewall-dr/terraform.tfstate"
#  }
#}

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
