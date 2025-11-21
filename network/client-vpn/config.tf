#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.client_vpn_config.region
  profile = var.profile
}

provider "aws" {
  alias   = "management"
  region  = var.client_vpn_config.region
  profile = "${var.client_vpn_config.metadata.name}-root-administrator"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

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
    region  = var.client_vpn_config.region
    profile = var.profile
    bucket  = var.bucket
    key     = "network/security-keys/terraform.tfstate"
  }
}

data "terraform_remote_state" "certs" {
  backend = "s3"
  config = {
    region  = var.client_vpn_config.region
    profile = var.profile
    bucket  = var.bucket
    key     = "network/security-certs/terraform.tfstate"
  }
}

# NOTE: The following remote state data sources are kept for backward compatibility
# but should be replaced with direct VPC ID and subnet ID references in client_vpn_config
# when migrating to the new structure. They reference locals that may not exist if
# client_vpn_config.connection.vpc_id and subnet_ids are provided directly.
data "terraform_remote_state" "network_vpcs" {
  for_each = try(local.remote_state_network_vpcs, {})

  backend = "s3"
  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

data "terraform_remote_state" "apps_devstg_vpcs" {
  for_each = try(local.remote_state_apps_devstg_vpcs, {})

  backend = "s3"
  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

data "terraform_remote_state" "apps_prd_vpcs" {
  for_each = try(local.remote_state_apps_prd_vpcs, {})

  backend = "s3"
  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}
