#
# Permissions boundary for the apply role. The role's own policy is already
# scoped to the allowlisted layers; this boundary keeps it from ever changing
# the CI identities themselves, even if a future target grants broad IAM
# rights: their roles, policies, boundaries, and the GitHub OIDC provider.
#
data "aws_iam_policy_document" "github_actions_opentofu_apply_boundary" {
  statement {
    sid       = "AllowWithinIdentityPolicy"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }

  statement {
    sid     = "DenyChangesToCiIdentities"
    effect  = "Deny"
    actions = ["iam:*"]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/GitHubActionsOpenTofu*",
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/GitHubActionsOpenTofu*",
      data.aws_iam_openid_connect_provider.github.arn,
    ]
  }

  statement {
    sid    = "DenyBoundaryRemoval"
    effect = "Deny"
    actions = [
      "iam:DeleteRolePermissionsBoundary",
      "iam:DeleteUserPermissionsBoundary",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_opentofu_apply_boundary" {
  name        = local.github_actions_opentofu_apply_boundary_name
  description = "Permissions boundary that keeps the OpenTofu apply role away from the CI identities"
  policy      = data.aws_iam_policy_document.github_actions_opentofu_apply_boundary.json
}
