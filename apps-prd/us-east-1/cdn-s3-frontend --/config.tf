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
  alias   = "shared-route53"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = "~> 4.0"
  }

  backend "s3" {
    key = "apps-prd/cdn-s3-frontend/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for security certs
#
# STALE — this layer is disabled (trailing " --"), and the `certificate_arn`
# output it reads no longer exists upstream. It exposed the *.binbash.com.ar
# certificate, which expired 2026-07-09 attached to nothing and INELIGIBLE for
# renewal; it was deleted from apps-prd/us-east-1/security-certs rather than
# replaced, because every apply on that layer failed on it. See #1143.
#
# Re-enabling this layer therefore requires provisioning its own certificate for
# www.binbash.com.ar / statics.binbash.com.ar first. Before doing that, check
# whether the layer is wanted at all: binbash.com.ar is now served by other
# infrastructure and 301s to binbash.co, which app-binbash-web serves.
#
data "terraform_remote_state" "certificates" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-certs/terraform.tfstate"
  }
}

#
# data type from output for dns
#
data "terraform_remote_state" "dns-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/dns/binbash.com.ar/terraform.tfstate"
  }
}
