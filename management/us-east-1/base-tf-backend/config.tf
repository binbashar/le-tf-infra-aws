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
  required_version = ">= 1.1.9"

  required_providers {
    aws = "~> 4.0"
  }

  backend "s3" {
    key = "root/tf-backend/terraform.tfstate"
  }
}
