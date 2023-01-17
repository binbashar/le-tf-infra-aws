#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

#=============================#
# Vault Provider Settings     #
#=============================#
provider "vault" {
  address = var.vault_address

  /*
  Vault token that will be used by Terraform to authenticate.
 admin token from https://portal.cloud.hashicorp.com/.
 */
  token = var.vault_token
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.2.7"

  required_providers {
    aws   = "~> 4.10"
    vault = "~> 3.6.0"
  }

  backend "s3" {
    key = "network/notifications/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for security
#
data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}

data "vault_generic_secret" "slack_hook_url_monitoring" {
  path = "secrets/${var.project}/${var.environment}/notifications"
}
