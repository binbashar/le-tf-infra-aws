#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = local.tags
  }
}

# The account that hosts the sending domain's public DNS zone.
# Keep the profile a literal "${var.project}-<account>-devops": Leverage reads it
# from this file to refresh that account's credentials, and skips local values.
provider "aws" {
  alias   = "dns"
  region  = var.region
  profile = "${var.project}-shared-devops"

  default_tags {
    tags = local.tags
  }
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    key = "management/cost-email-report/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#

#
# The sending domain's public zone, in the same account as the aws.dns
# provider (keep the two in step). Not read when manage_dns_records = false,
# so an installation without access to that state can still create the
# identity and get the dkim_records output.
#
data "terraform_remote_state" "dns" {
  count   = var.manage_dns_records ? 1 : 0
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = var.dns_state_key != "" ? var.dns_state_key : "shared/dns/${var.ses_domain}/terraform.tfstate"
  }
}

#
# The monitoring SNS topic (Slack) the errors alarm notifies, unless
# alarm_sns_topic_arn names another one
#
data "terraform_remote_state" "notifications" {
  count   = var.alarm_sns_topic_arn == "" ? 1 : 0
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/notifications/terraform.tfstate"
  }
}
