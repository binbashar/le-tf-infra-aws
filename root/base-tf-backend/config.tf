#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  alias                   = "main_region"
  version                 = "~> 3.0"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

provider "aws" {
  alias                   = "secondary_region"
  version                 = "~> 3.0"
  region                  = var.region_secondary
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

terraform {
  required_version = ">= 0.12.28"

  backend "s3" {
    key = "root/tf-backend/terraform.tfstate"
  }
}

provider "null" {
  version = "~> 2.1"
}
