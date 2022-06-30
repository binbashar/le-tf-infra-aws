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
  required_version = ">= 1.0.9"

  required_providers {
    aws   = "~> 3.2"
    vault = "~> 2.18.0"
  }

  backend "s3" {
    key = "security/security-monitoring/terraform.tfstate"
  }
}

data "vault_generic_secret" "slack_hook_url_monitoring" {
  path = "secrets/${var.project}/${var.environment}/security-monitoring"
}
