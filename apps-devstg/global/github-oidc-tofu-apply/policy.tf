locals {
  apply_state_object_arns = [
    for target in values(local.apply_targets) :
    "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}/${target.state_key}"
  ]
  apply_state_lock_keys = flatten([
    for target in values(local.apply_targets) : [
      "${var.bucket}/${target.state_key}",
      "${var.bucket}/${target.state_key}-md5",
    ]
  ])
}

# Backend access shared by every apply target. The workflow will narrow each job
# to its own layer's state object and lock keys with an inline session policy.
data "aws_iam_policy_document" "github_actions_opentofu_apply_state" {
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
      values   = [for target in values(local.apply_targets) : target.state_key]
    }
  }

  # Read and write, never delete: the bucket is versioned, and keeping every
  # state version is what makes an apply auditable and recoverable.
  statement {
    sid       = "ReadWriteTargetState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = local.apply_state_object_arns
  }

  statement {
    sid    = "DenyTargetStateDeletion"
    effect = "Deny"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
    ]
    resources = local.apply_state_object_arns
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
      values   = local.apply_state_lock_keys
    }
  }
}

data "aws_iam_policy_document" "github_actions_opentofu_apply" {
  source_policy_documents = [
    data.aws_iam_policy_document.github_actions_opentofu_apply_state.json,
    data.aws_iam_policy_document.github_actions_opentofu_apply_cli_test_layer.json,
  ]
}

resource "aws_iam_policy" "github_actions_opentofu_apply" {
  name        = local.github_actions_opentofu_apply_policy_name
  description = "Least-privilege backend and resource writes for GitHub Actions OpenTofu applies"
  policy      = data.aws_iam_policy_document.github_actions_opentofu_apply.json
}

resource "aws_iam_role_policy_attachment" "github_actions_opentofu_apply" {
  role       = aws_iam_role.github_actions_opentofu_apply.name
  policy_arn = aws_iam_policy.github_actions_opentofu_apply.arn
}
