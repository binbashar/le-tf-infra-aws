#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

# binbash-shared route53 cross-account DNS records — the public binbash.co zone
# lives in the shared account, so the alias record for forms.binbash.co is
# created through this provider, exactly as app-binbash-web does.
provider "aws" {
  region  = var.region
  profile = "${var.project}-shared-devops"
  alias   = "shared-route53"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = "~> 6.0"
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  backend "s3" {
    key = "apps-prd/app-binbash-web-forms/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# The public binbash.co zone, for the forms.binbash.co alias record
#
data "terraform_remote_state" "dns-binbash-co" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/dns/binbash.co/terraform.tfstate"
  }
}

#
# ACM certificates. forms.binbash.co is created in the security-certs layer —
# that is where this account keeps every certificate. See its forms.binbash.co.tf.
#
data "terraform_remote_state" "certificates" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-prd/security-certs/terraform.tfstate"
  }
}

#
# The SES domain identity for binbash.co, created by the app-ai-lab layer. This
# layer sends as careers@binbash.co under that identity rather than declaring a
# second identity for the same domain.
#
data "terraform_remote_state" "ai-lab" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-prd/app-ai-lab/terraform.tfstate"
  }
}
