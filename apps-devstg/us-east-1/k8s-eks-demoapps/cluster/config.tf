#
# Providers
#
provider "aws" {
  region  = var.region
  profile = var.profile
}

#
# Backend Config (partial)
#
terraform {
  required_version = "~> 1.6"

  required_providers {
    # terraform-aws-eks v21 requires the AWS provider >= 6.59.
    aws = "~> 6.59"
  }

  backend "s3" {
    key = "apps-devstg/k8s-eks-demoapps/cluster/terraform.tfstate"
  }
}

#
# Data Sources
#

# The `kubernetes` provider used to live here purely to feed the `aws-auth`
# submodule, which v21 removed. This layer holds no `kubernetes_*` resources, so
# the provider -- and the `aws_eks_cluster_auth` token data source that fed it --
# are gone. A useful side effect: applying this layer no longer touches the
# (private) Kubernetes API, so it no longer needs VPN access. Cluster access is
# granted through EKS access entries instead; see `locals.tf`.

# Resolves the IAM Identity Center DevOps permission set role, whose name suffix
# is generated and changes whenever the permission set is recreated. See
# `local.sso_devops_role_arn`.
#
# The regex is anchored, and the count is asserted, because `local.sso_devops_role_arn`
# reduces this with `one()` and both of its failure modes are illegible:
#
#   - **No match** -> `one()` returns `null`, `principal_arn = null` reaches
#     `aws_eks_access_entry`, and the apply fails with a provider-level
#     invalid-argument error naming neither this data source nor the permission
#     set. That is a live possibility, not a hypothetical: the DevOps assignment
#     for this account is made in `management/global/sso` -- a different layer,
#     in a different account, applied by someone else. Remove or re-scope it and
#     this apply breaks with no clue as to why.
#   - **Two or more matches** -> a bare cardinality error. Unanchored,
#     `AWSReservedSSO_DevOps_.*` would also match a future `DevOps_ReadOnly`
#     permission set. There is exactly one `DevOps` set today, so the anchor is
#     a guard against a name that does not exist yet.
#
# The anchored form also documents the shape the comment above describes: the
# suffix IAM Identity Center generates is hex.
#
# **Not sourced from `management/global/sso`, and that is not an oversight.**
# The obvious-looking alternative -- read it from the layer that creates the
# permission set, via `terraform_remote_state` -- cannot work, for three reasons
# that compound:
#
#   1. That layer exports nothing; it has no `outputs.tf` at all.
#   2. Even with one, there is nothing to export. Checked against the provider
#      this layer actually uses (aws 6.47.0): `aws_ssoadmin_permission_set`
#      carries only `arn`, `name`, `description`, `relay_state`,
#      `session_duration`, `created_date`, `instance_arn` and `tags`. No
#      `aws_ssoadmin_*` data source exposes the provisioned role name or its
#      suffix, because no AWS API returns the mapping -- Identity Center
#      materialises the role in each target account and does not publish the
#      correspondence back through the SSO admin API.
#   3. The permission set lives in the management account against the SSO
#      instance; the role it materialises lives *here*, in apps-devstg. They are
#      different objects in different accounts, and only the second one is an
#      EKS access-entry principal.
#
# So `iam:ListRoles` filtered by the reserved prefix is the mapping, and this
# data source is it. It is already the "resolve, don't pin" fix -- the thing it
# replaced was a hardcoded ARN that had silently gone stale.
data "aws_iam_roles" "sso_devops" {
  name_regex  = "^AWSReservedSSO_DevOps_[0-9a-f]+$"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"

  lifecycle {
    postcondition {
      condition     = length(self.arns) == 1
      error_message = "Expected exactly one AWSReservedSSO_DevOps_* role in this account, found ${length(self.arns)}. Check that the DevOps permission set is still assigned to apps-devstg in management/global/sso."
    }
  }
}

data "terraform_remote_state" "cluster-vpc" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "keys" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "apps-devstg/security-keys/terraform.tfstate"
  }
}

data "terraform_remote_state" "shared-vpc" {
  backend = "s3"
  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/network/terraform.tfstate"
  }
}
