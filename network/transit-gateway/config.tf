#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = local.region
  profile = var.profile
}

provider "aws" {
  alias   = "network"
  region  = local.region
  profile = var.profile
}

provider "aws" {
  alias   = "shared"
  region  = local.region
  profile = "${local.project}-shared-devops"
}

provider "aws" {
  alias   = "apps-devstg"
  region  = local.region
  profile = "${local.project}-apps-devstg-devops"
}

provider "aws" {
  alias   = "apps-prd"
  region  = local.region
  profile = "${local.project}-apps-prd-devops"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 4.0"
  }

  backend "s3" {
    key = "network/transit-gateway/terraform.tfstate"
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
    region  = local.region
    profile = "${local.project}-shared-devops"
    bucket  = "${local.project}-shared-terraform-backend"
    key     = "shared/vpn-server/terraform.tfstate"
  }
}

# Network Firewall
data "terraform_remote_state" "network-firewall" {

  backend = "s3"

  config = {
    region  = local.region
    profile = "${local.project}-network-devops"
    bucket  = "${local.project}-network-terraform-backend"
    key     = "network/network-firewall/terraform.tfstate"

  }
}

# Transit Gateway in the secondary region
data "terraform_remote_state" "tgw-dr" {

  backend = "s3"

  config = {
    region  = local.region
    profile = "${local.project}-network-devops"
    bucket  = "${local.project}-network-terraform-backend"
    key     = "network/transit-gateway-dr/terraform.tfstate"
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

#
# Secondary region
#

# VPC remote states for share-dr
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

# VPC remote states for network-dr
data "terraform_remote_state" "network-dr-vpcs" {

  for_each = local.network-dr-vpcs

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
