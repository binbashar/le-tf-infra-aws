data "aws_iam_policy_document" "github_actions_opentofu_noop" {
  statement {
    sid     = "ReadStateBackendMetadata"
    effect  = "Allow"
    actions = ["s3:GetBucketLocation"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}",
    ]
  }

  statement {
    sid     = "ListNoopState"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = [local.noop_target_state_key]
    }
  }

  statement {
    sid     = "ReadNoopState"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}/${local.noop_target_state_key}",
    ]
  }

  statement {
    sid    = "DenyNoopStateMutation"
    effect = "Deny"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:PutObject",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}/${local.noop_target_state_key}",
    ]
  }

  statement {
    sid     = "DescribeStateLockTable"
    effect  = "Allow"
    actions = ["dynamodb:DescribeTable"]
    resources = [
      "arn:${data.aws_partition.current.partition}:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table}",
    ]
  }

  statement {
    sid    = "ManageNoopStateLockItems"
    effect = "Allow"
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table}",
    ]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "dynamodb:LeadingKeys"
      values = [
        "${var.bucket}/${local.noop_target_state_key}",
        "${var.bucket}/${local.noop_target_state_key}-md5",
      ]
    }
  }

  statement {
    sid    = "ReadGitHubOidcProvider"
    effect = "Allow"
    actions = [
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviderTags",
    ]
    resources = [aws_iam_openid_connect_provider.github.arn]
  }

  statement {
    sid    = "ReadBootstrapRoles"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListRoleTags",
    ]
    resources = [
      for name in [
        local.github_actions_opentofu_plan_role_name,
        local.github_actions_opentofu_noop_role_name,
        local.github_actions_opentofu_bedrock_role_name,
      ] : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${name}"
    ]
  }

  statement {
    sid    = "ReadBootstrapPolicies"
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
    ]
    resources = [
      for name in [
        local.github_actions_opentofu_plan_policy_name,
        local.github_actions_opentofu_noop_policy_name,
        local.github_actions_opentofu_bedrock_policy_name,
      ] : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${name}"
    ]
  }
}

resource "aws_iam_policy" "github_actions_opentofu_noop" {
  name        = local.github_actions_opentofu_noop_policy_name
  description = "Least-privilege backend and IAM reads for a no-change OpenTofu plan"
  policy      = data.aws_iam_policy_document.github_actions_opentofu_noop.json
}

resource "aws_iam_role_policy_attachment" "github_actions_opentofu_noop" {
  role       = aws_iam_role.github_actions_opentofu_noop.name
  policy_arn = aws_iam_policy.github_actions_opentofu_noop.arn
}
