#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 2.69"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/${var.project}/config"
}

terraform {
  required_version = ">= 0.12.28"

    backend "s3" {
    key = "shared/tf-backend/terraform.tfstate"
  }
}

provider "null" {
  version = "~> 2.1"
}
