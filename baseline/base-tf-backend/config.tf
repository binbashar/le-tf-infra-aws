#=============================#
# AWS Provider Settings       #
#=============================#
# Default provider configuration
provider "aws" {
  region = var.region_primary
}

provider "aws" {
  alias    = "accounts"
  for_each = local.accounts_providers
  region   = each.value.region

}

terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 5.0"
  }

  //backend "s3" {
  //  key    = local.backend_settings.bucket.key
  //}
}

