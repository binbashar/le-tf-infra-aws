#
# Provider reads needed to refresh apps-devstg/global/cli-test-layer, the
# intentionally unprovisioned test layer: it only reads its own role and policy.
#
locals {
  cli_test_layer_role_name   = "LeverageTest"
  cli_test_layer_policy_name = "leverage_test"
}

data "aws_iam_policy_document" "github_actions_opentofu_plan_cli_test_layer" {
  statement {
    sid    = "ReadTargetRole"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListRoleTags",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.cli_test_layer_role_name}",
    ]
  }

  statement {
    sid    = "ReadTargetPolicy"
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cli_test_layer_policy_name}",
    ]
  }
}
