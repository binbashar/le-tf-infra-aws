#
# Provider reads needed to refresh management/global/sso.
#
# Derived from the CloudTrail events of a converged local plan on 2026-10-11
# (191 resources). Everything is read-only and scoped to this organization's
# IAM Identity Center instance and its identity store. sso:ListTagsForResource
# on applications was added after the first CI plan was denied it.
#
data "aws_ssoadmin_instances" "main" {}

locals {
  sso_instance_arn      = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  sso_instance_id       = element(split("/", local.sso_instance_arn), 1)
  sso_identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

data "aws_iam_policy_document" "github_actions_opentofu_plan_sso" {
  statement {
    sid       = "ListSsoInstances"
    effect    = "Allow"
    actions   = ["sso:ListInstances"]
    resources = ["*"]
  }

  statement {
    sid    = "ReadSsoPermissionSetsAndAssignments"
    effect = "Allow"
    actions = [
      "sso:DescribePermissionSet",
      "sso:GetInlinePolicyForPermissionSet",
      "sso:ListAccountAssignments",
      "sso:ListManagedPoliciesInPermissionSet",
      "sso:ListTagsForResource",
    ]
    resources = [
      local.sso_instance_arn,
      "arn:${data.aws_partition.current.partition}:sso:::permissionSet/${local.sso_instance_id}/*",
      "arn:${data.aws_partition.current.partition}:sso:::account/*",
    ]
  }

  statement {
    sid    = "ReadSsoApplications"
    effect = "Allow"
    actions = [
      "sso:DescribeApplication",
      "sso:DescribeApplicationAssignment",
      "sso:ListTagsForResource",
    ]
    resources = [
      local.sso_instance_arn,
      "arn:${data.aws_partition.current.partition}:sso::${data.aws_caller_identity.current.account_id}:application/${local.sso_instance_id}/*",
    ]
  }

  statement {
    sid    = "ReadIdentityStore"
    effect = "Allow"
    actions = [
      "identitystore:DescribeGroup",
      "identitystore:DescribeGroupMembership",
      "identitystore:DescribeUser",
      "identitystore:GetGroupId",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:identitystore::${data.aws_caller_identity.current.account_id}:identitystore/${local.sso_identity_store_id}",
      "arn:${data.aws_partition.current.partition}:identitystore:::user/*",
      "arn:${data.aws_partition.current.partition}:identitystore:::group/*",
      "arn:${data.aws_partition.current.partition}:identitystore:::membership/*",
    ]
  }
}
