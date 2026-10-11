locals {
  plan_state_object_arns = [
    for target in values(local.plan_targets) :
    "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}/${target.state_key}"
  ]
  plan_state_lock_keys = flatten([
    for target in values(local.plan_targets) : [
      "${var.bucket}/${target.state_key}",
      "${var.bucket}/${target.state_key}-md5",
    ]
  ])
}

# Backend access shared by every plan target. The workflow narrows each job to
# its own layer's state object and lock keys with an inline session policy.
data "aws_iam_policy_document" "github_actions_opentofu_plan_state" {
  statement {
    sid     = "ReadStateBackendMetadata"
    effect  = "Allow"
    actions = ["s3:GetBucketLocation"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}",
    ]
  }

  statement {
    sid     = "ListTargetState"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = [for target in values(local.plan_targets) : target.state_key]
    }
  }

  statement {
    sid       = "ReadTargetState"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = local.plan_state_object_arns
  }

  # A speculative plan must never persist refreshed state. This explicit deny
  # remains effective if an allow is accidentally attached to the role later.
  statement {
    sid    = "DenyTargetStateMutation"
    effect = "Deny"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:PutObject",
    ]
    resources = local.plan_state_object_arns
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
    sid    = "ManageTargetStateLockItems"
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
      values   = local.plan_state_lock_keys
    }
  }
}

data "aws_iam_policy_document" "github_actions_opentofu_plan" {
  source_policy_documents = [
    data.aws_iam_policy_document.github_actions_opentofu_plan_state.json,
    data.aws_iam_policy_document.github_actions_opentofu_plan_sso.json,
  ]
}

resource "aws_iam_policy" "github_actions_opentofu_plan" {
  name        = local.github_actions_opentofu_plan_policy_name
  description = "Least-privilege backend and provider reads for GitHub Actions OpenTofu plans"
  policy      = data.aws_iam_policy_document.github_actions_opentofu_plan.json
}

resource "aws_iam_role_policy_attachment" "github_actions_opentofu_plan" {
  role       = aws_iam_role.github_actions_opentofu_plan.name
  policy_arn = aws_iam_policy.github_actions_opentofu_plan.arn
}
