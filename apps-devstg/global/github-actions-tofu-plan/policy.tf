data "aws_iam_policy_document" "github_actions_plan" {
  statement {
    sid     = "ReadBackendBucketMetadata"
    effect  = "Allow"
    actions = ["s3:GetBucketLocation"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}",
    ]
  }

  statement {
    sid     = "ListPilotState"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = [local.pilot_state_key]
    }
  }

  statement {
    sid    = "ReadPilotState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}/${local.pilot_state_key}",
    ]
  }

  # A speculative plan must never persist refreshed state. This explicit deny
  # remains effective if an allow is accidentally attached to the role later.
  statement {
    sid    = "DenyPilotStateMutation"
    effect = "Deny"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:PutObject",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket}/${local.pilot_state_key}",
    ]
  }

  statement {
    sid     = "DescribePilotStateLockTable"
    effect  = "Allow"
    actions = ["dynamodb:DescribeTable"]
    resources = [
      "arn:${data.aws_partition.current.partition}:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table}",
    ]
  }

  statement {
    sid    = "ManagePilotStateLockItems"
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
        "${var.bucket}/${local.pilot_state_key}",
        "${var.bucket}/${local.pilot_state_key}-md5",
      ]
    }
  }

  statement {
    sid    = "ReadPilotRole"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListRoleTags",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.pilot_role_name}",
    ]
  }

  statement {
    sid    = "ReadPilotPolicy"
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.pilot_policy_name}",
    ]
  }
}

resource "aws_iam_policy" "github_actions_plan" {
  name        = local.github_actions_plan_policy_name
  description = "Least-privilege backend and IAM reads for the OpenTofu plan POC"
  policy      = data.aws_iam_policy_document.github_actions_plan.json
}

resource "aws_iam_role_policy_attachment" "github_actions_plan" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = aws_iam_policy.github_actions_plan.arn
}
