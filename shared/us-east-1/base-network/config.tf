#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "apps-devstg"
  region  = var.region
  profile = "${var.project}-apps-devstg-devops"
}

provider "aws" {
  alias   = "apps-devstg-dr"
  region  = var.region_secondary
  profile = "${var.project}-apps-devstg-devops"
}

provider "aws" {
  alias   = "apps-prd"
  region  = var.region
  profile = "${var.project}-apps-prd-devops"
}

provider "aws" {
  alias   = "apps-prd-dr"
  region  = var.region_secondary
  profile = "${var.project}-apps-prd-devops"
}

provider "aws" {
  alias   = "shared-dr"
  region  = var.region_secondary
  profile = "${var.project}-shared-devops"
}

provider "aws" {
  alias   = "security"
  region  = var.region
  profile = "${var.project}-security-devops"
}

provider "aws" {
  alias   = "data-science"
  region  = var.region
  profile = "${var.project}-data-science-devops"
}


#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.2"

  required_providers {
    aws = "~> 4.10"
  }

  backend "s3" {
    key = "shared/network/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

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
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/vpn-server/terraform.tfstate"
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

# VPC remote states for apps-devstg-dr
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

# VPC remote states for security
data "terraform_remote_state" "security-vpcs" {

  for_each = local.security-vpcs

  backend = "s3"

  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

# VPC remote states for security
data "terraform_remote_state" "data-science-vpcs" {

  for_each = local.data-science-vpcs

  backend = "s3"

  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}