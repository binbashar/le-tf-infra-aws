#
# Provider calls needed to create, update, refresh, and destroy
# management/global/sso: permission sets and their policies, account
# assignments, the Client VPN application, and identity store users, groups,
# and memberships.
#
# The reads match github-oidc-tofu-plan's plan-target-sso.tf. The writes are
# the OpenTofu write events of the manual sso applies in CloudTrail (90 days,
# 2026-07-22 to 2026-10-13), plus their update and delete counterparts. The
# layer makes no IAM writes: Identity Center creates the account roles itself.
#
# Writing to Identity Center is close to admin of the organization: an
# approved PR can assign any permission set to anyone. The controls are the
# tofu-apply approval by the admin team and the digest check. The one guard
# here keeps a mistaken apply from locking everyone out: the Administrator
# permission set and its assignments cannot be changed by this role, so those
# changes stay manual.
#
data "aws_ssoadmin_instances" "main" {}

locals {
  sso_instance_arn      = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  sso_instance_id       = element(split("/", local.sso_instance_arn), 1)
  sso_identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  sso_permission_sets_arn = "arn:${data.aws_partition.current.partition}:sso:::permissionSet/${local.sso_instance_id}/*"
  sso_accounts_arn        = "arn:${data.aws_partition.current.partition}:sso:::account/*"
  sso_applications_arn    = "arn:${data.aws_partition.current.partition}:sso::${data.aws_caller_identity.current.account_id}:application/${local.sso_instance_id}/*"
  identity_store_arns = [
    "arn:${data.aws_partition.current.partition}:identitystore::${data.aws_caller_identity.current.account_id}:identitystore/${local.sso_identity_store_id}",
    "arn:${data.aws_partition.current.partition}:identitystore:::user/*",
    "arn:${data.aws_partition.current.partition}:identitystore:::group/*",
    "arn:${data.aws_partition.current.partition}:identitystore:::membership/*",
  ]
}

data "aws_ssoadmin_permission_set" "administrator" {
  instance_arn = local.sso_instance_arn
  name         = "Administrator"
}

data "aws_iam_policy_document" "github_actions_opentofu_apply_sso" {
  statement {
    sid       = "ListSsoInstances"
    effect    = "Allow"
    actions   = ["sso:ListInstances"]
    resources = ["*"]
  }

  statement {
    sid    = "ManagePermissionSetsAndAssignments"
    effect = "Allow"
    actions = [
      "sso:AttachCustomerManagedPolicyReferenceToPermissionSet",
      "sso:AttachManagedPolicyToPermissionSet",
      "sso:CreateAccountAssignment",
      "sso:CreatePermissionSet",
      "sso:DeleteAccountAssignment",
      "sso:DeleteInlinePolicyFromPermissionSet",
      "sso:DeletePermissionSet",
      "sso:DeletePermissionsBoundaryFromPermissionSet",
      "sso:DescribeAccountAssignmentCreationStatus",
      "sso:DescribeAccountAssignmentDeletionStatus",
      "sso:DescribePermissionSet",
      "sso:DescribePermissionSetProvisioningStatus",
      "sso:DetachCustomerManagedPolicyReferenceFromPermissionSet",
      "sso:DetachManagedPolicyFromPermissionSet",
      "sso:GetInlinePolicyForPermissionSet",
      "sso:GetPermissionsBoundaryForPermissionSet",
      "sso:ListAccountAssignments",
      "sso:ListAccountsForProvisionedPermissionSet",
      "sso:ListCustomerManagedPolicyReferencesInPermissionSet",
      "sso:ListManagedPoliciesInPermissionSet",
      "sso:ListTagsForResource",
      "sso:ProvisionPermissionSet",
      "sso:PutInlinePolicyToPermissionSet",
      "sso:PutPermissionsBoundaryToPermissionSet",
      "sso:TagResource",
      "sso:UntagResource",
      "sso:UpdatePermissionSet",
    ]
    resources = [
      local.sso_instance_arn,
      local.sso_permission_sets_arn,
      local.sso_accounts_arn,
    ]
  }

  statement {
    sid    = "ManageSsoApplications"
    effect = "Allow"
    actions = [
      "sso:CreateApplication",
      "sso:CreateApplicationAssignment",
      "sso:DeleteApplication",
      "sso:DeleteApplicationAssignment",
      "sso:DescribeApplication",
      "sso:DescribeApplicationAssignment",
      "sso:ListTagsForResource",
      "sso:TagResource",
      "sso:UntagResource",
      "sso:UpdateApplication",
    ]
    resources = [
      local.sso_instance_arn,
      local.sso_applications_arn,
    ]
  }

  statement {
    sid    = "ManageIdentityStore"
    effect = "Allow"
    actions = [
      "identitystore:CreateGroup",
      "identitystore:CreateGroupMembership",
      "identitystore:CreateUser",
      "identitystore:DeleteGroup",
      "identitystore:DeleteGroupMembership",
      "identitystore:DeleteUser",
      "identitystore:DescribeGroup",
      "identitystore:DescribeGroupMembership",
      "identitystore:DescribeUser",
      "identitystore:GetGroupId",
      "identitystore:UpdateGroup",
      "identitystore:UpdateUser",
    ]
    resources = local.identity_store_arns
  }

  # Anti-lockout: the Administrator permission set, its policies, and its
  # assignments are changed by hand, never by CI. A PR that touches them fails
  # at apply with AccessDenied and keeps the lock; apply it manually.
  statement {
    sid    = "DenyAdministratorPermissionSetChanges"
    effect = "Deny"
    actions = [
      "sso:AttachCustomerManagedPolicyReferenceToPermissionSet",
      "sso:AttachManagedPolicyToPermissionSet",
      "sso:CreateAccountAssignment",
      "sso:DeleteAccountAssignment",
      "sso:DeleteInlinePolicyFromPermissionSet",
      "sso:DeletePermissionSet",
      "sso:DeletePermissionsBoundaryFromPermissionSet",
      "sso:DetachCustomerManagedPolicyReferenceFromPermissionSet",
      "sso:DetachManagedPolicyFromPermissionSet",
      "sso:ProvisionPermissionSet",
      "sso:PutInlinePolicyToPermissionSet",
      "sso:PutPermissionsBoundaryToPermissionSet",
      "sso:TagResource",
      "sso:UntagResource",
      "sso:UpdatePermissionSet",
    ]
    resources = [data.aws_ssoadmin_permission_set.administrator.arn]
  }
}
