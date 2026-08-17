#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "management"
  region  = var.region
  profile = "${var.project}-root-administrator"
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
    key = "network/client-vpn/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

data "terraform_remote_state" "keys" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "network/security-keys/terraform.tfstate"
  }
}

# STALE — the `certificate_arn` output this reads no longer exists. It exposed the
# `*.binbash.com.ar` certificate, which expired 2026-02-12 attached to nothing and INELIGIBLE for
# renewal, and was deleted from `network/us-east-1/security-certs` rather than replaced. See #1145.
#
# Deploying this layer therefore needs a server certificate provisioned first. Note what kind: this
# endpoint uses `type = "federated-authentication"` (SAML via AWS SSO), so only a **server**
# certificate is required — there is no client/mutual-auth CA to import. A public ACM certificate
# covering the endpoint's DNS name is the normal choice, and `security-certs` is where it belongs.
#
# This is not the only thing gating a deploy: `client-vpn.tf` reads `saml-metadata.xml`, which is
# gitignored and must be created by hand first (see this layer's README).
data "terraform_remote_state" "certs" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "network/security-certs/terraform.tfstate"
  }
}

data "terraform_remote_state" "network_vpcs" {
  for_each = local.network_vpcs

  backend = "s3"
  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

data "terraform_remote_state" "apps_devstg_vpcs" {
  for_each = local.apps_devstg_vpcs

  backend = "s3"
  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

data "terraform_remote_state" "apps_prd_vpcs" {
  for_each = local.apps_prd_vpcs

  backend = "s3"
  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}
