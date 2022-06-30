#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  alias   = "main_region"
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "secondary_region"
  region  = var.region_secondary
  profile = var.profile
}

terraform {
  required_version = ">= 0.14.11"

  required_providers {
    aws = "~> 3.0"
  }

  backend "s3" {
    key = "security/tf-backend/terraform.tfstate"
  }
}
