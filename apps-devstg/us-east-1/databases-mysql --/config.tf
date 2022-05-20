#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
  # uncomment this 2 lines for aws sso disable
  # shared_credentials_files = ["~/.aws/${var.project}/credentials"]
  # shared_config_files      = ["~/.aws/${var.project}/config"]
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
  required_version = "~> 1.1.3"

  required_providers {
    aws   = "~> 4.0"
    vault = "~> 3.6.0"
  }

  backend "s3" {
    key = "apps-devstg/databases-mysql/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/network/terraform.tfstate"
  }
}

data "vault_generic_secret" "database_secrets" {
  path = "secrets/${var.project}/${var.environment}/databases-mysql"
}
