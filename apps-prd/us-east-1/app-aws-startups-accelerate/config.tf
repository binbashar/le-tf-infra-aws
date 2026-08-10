#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

# binbash-shared route53 cross-account DNS records
# (CloudFront alias records live in the shared account binbash.co zone)
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
    # terraform-aws-cloudfront-s3-cdn v2.x requires aws >= 6.13
    aws = "~> 6.0"
  }

  backend "s3" {
    key = "apps-prd/app-aws-startups-accelerate/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# data type from output for dns
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
# data type from output for certificates (ACM us-east-1, required by CloudFront)
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
# data type from output for notifications (SNS topics for CloudWatch alarms)
#
data "terraform_remote_state" "notifications" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/notifications/terraform.tfstate"
  }
}
