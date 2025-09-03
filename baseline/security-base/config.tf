#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  alias   = "accounts"
  for_each = local.account_settings
  region  = each.value.region

  access_key = each.value.access_key
  secret_key = each.value.secret_key
  token = each.value.token

}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = "~> 4.10"
  }

  # Backend commented out to avoid initialization prompts
  # Uncomment and configure when ready to use S3 backend
  #backend "s3" {
  #  key = "baseline/${local.account_name}/security-base/terraform.tfstate"
  #}
}
