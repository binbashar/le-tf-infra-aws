#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
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
    key = "apps-devstg/secrets-manager/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}
# Note: Commented out while database is not deployed
# data "terraform_remote_state" "apps-devstg-pgsql" {
#   backend = "s3"

#   config = {
#     region  = var.region
#     profile = var.profile
#     bucket  = var.bucket
#     key     = "${var.environment}/databases-pgsql/terraform.tfstate"
#   }
# }

# Note: Commented out while database is not deployed
# data "terraform_remote_state" "apps-devstg-aurora-pgsql" {
#   backend = "s3"

#   config = {
#     region  = var.region
#     profile = var.profile
#     bucket  = var.bucket
#     key     = "${var.environment}/databases-aurora-pgsql/terraform.tfstate"
#   }
# }
