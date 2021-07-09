#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "network"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "shared"
  region                  = var.region
  profile                 = "${var.project}-shared-devops"
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "apps-devstg"
  region                  = var.region
  profile                 = "${var.project}-apps-devstg-devops"
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "apps-prd"
  region                  = var.region
  profile                 = "${var.project}-apps-prd-devops"
  shared_credentials_file = "~/.aws/${var.project}/config"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 0.14.11"

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

#
# data type from output for tools-ec2
#
data "terraform_remote_state" "tools-vpn-server" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/vpn/terraform.tfstate"
  }
}

# VPC remote states for network
data "terraform_remote_state" "network-vpcs" {
  for_each = local.network-vpcs

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
