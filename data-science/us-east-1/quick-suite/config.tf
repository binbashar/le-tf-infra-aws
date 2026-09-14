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

#
# IAM Identity Center is an organization instance owned by the management
# account, so the group lookups in sso-groups.tf have to run there: this
# account's own credentials get AccessDenied on the identity store.
#
provider "aws" {
  alias   = "management"
  region  = var.region
  profile = "${var.project}-management-administrator"
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    # 5.100 is the floor that carries `aws_quicksight_role_membership` and
    # `iam_identity_center_instance_arn` on the subscription resource. The Pro
    # tier arguments (`admin_pro_group` and siblings) only land in 6.x -- see
    # README.md before reaching for them.
    aws = "~> 5.100"
  }

  backend "s3" {
    key = "data-science/quick-suite/terraform.tfstate"
  }
}
