terraform {
    required_version = ">= 0.12.18"
}

provider "aws" {
  version = "~> 2.43"
  region  = var.region
  profile = var.profile
}

provider "null" {
  version = "~> 2.1"
}