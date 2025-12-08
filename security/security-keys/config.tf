#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  alias    = "by_region"
  for_each = toset(var.regions)
  region   = each.value
  #profile  = var.profile
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 5.0"
  }

  #backend "s3" {
  #  key = "security/security-keys/terraform.tfstate"
  #}
}
