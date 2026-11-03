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

# The account that hosts the sending domain's public DNS zone (var.dns_account)
provider "aws" {
  alias   = "dns"
  region  = var.region
  profile = local.dns_profile

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
# The sending domain's public zone, in var.dns_account. Not read when
# manage_dns_records = false, so an installation without access to that
# state can still create the identity and get the dkim_records output.
#
data "terraform_remote_state" "dns" {
  count   = var.manage_dns_records ? 1 : 0
  backend = "s3"

  config = {
    region  = var.region
    profile = local.dns_profile
    bucket  = local.dns_bucket
    key     = local.dns_state_key
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
