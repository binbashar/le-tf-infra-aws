#
# Provider calls needed to create, update, refresh, and destroy
# apps-devstg/global/cli-test-layer: one managed policy, one role, and the
# attachment between them (AWS provider 4.x, iam-assumable-role module v4.24.1).
#
# Deliberately absent: iam:PutRolePolicy (the layer has no inline policy),
# permissions-boundary changes, and iam:PassRole. The attachment is limited to
# the layer's own policy, so the role cannot be given a broader managed policy.
#
locals {
  cli_test_layer_role_arn   = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/LeverageTest"
  cli_test_layer_policy_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/leverage_test"
}

data "aws_iam_policy_document" "github_actions_opentofu_apply_cli_test_layer" {
  statement {
    sid    = "ManageTargetRole"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
      "iam:ListRoleTags",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
    ]
    resources = [local.cli_test_layer_role_arn]
  }

  statement {
    sid    = "AttachOnlyTheTargetPolicy"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]
    resources = [local.cli_test_layer_role_arn]

    condition {
      test     = "ArnEquals"
      variable = "iam:PolicyARN"
      values   = [local.cli_test_layer_policy_arn]
    }
  }

  statement {
    sid    = "ManageTargetPolicy"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = [local.cli_test_layer_policy_arn]
  }
}
