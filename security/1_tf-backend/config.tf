#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  version                 = "~> 2.46"
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = "~/.aws/config"
}

terraform {
  required_version = ">= 0.12.20"
}

provider "null" {
  version = "~> 2.1"
}
