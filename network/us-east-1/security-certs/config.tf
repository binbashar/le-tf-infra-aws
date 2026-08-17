#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

# Here we need a different AWS provider because ACM certificates
# DNS validation records needs to be created in binbash-shared account
#
# binbash-shared route53 cross-account ACM dns validation update
#
provider "aws" {
  region  = var.region
  profile = "${var.project}-shared-devops"
  alias   = "shared"
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
    key = "network/security-certs/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

# This layer currently declares no certificates — see #1145. The `aws.shared` provider alias above
# is kept deliberately: any certificate added here needs it, because ACM DNS validation records for
# these domains live in the shared account's Route 53 zones.
#
# The `shared-dns` remote state data source that used to live here was removed with the certificate.
# Unlike an inert provider declaration, a data source is read on every plan — so keeping it would
# cost a cross-account S3 read for nothing, and would rot silently if the upstream output shape
# changed. Re-add it alongside whatever certificate needs it.
