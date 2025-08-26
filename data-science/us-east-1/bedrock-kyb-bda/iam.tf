data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid    = "CloudWatchLogsCreateGroup"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup"
    ]

    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    sid    = "CloudWatchLogsStreamAndEvents"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_function_name}:*"]
  }

  statement {
    sid    = "S3Access"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.kyb_input.arn}/*",
      "${aws_s3_bucket.kyb_output.arn}/*"
    ]
  }

  statement {
    sid    = "S3BucketAccess"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [
      aws_s3_bucket.kyb_input.arn,
      aws_s3_bucket.kyb_output.arn
    ]
  }

  statement {
    sid    = "BedrockDataAutomation"
    effect = "Allow"

    actions = [
      "bedrock:InvokeDataAutomation",
      "bedrock:InvokeDataAutomationAsync",
      "bedrock:GetDataAutomationProject",
      "bedrock:ListDataAutomationProjects"
    ]

    resources = [
      "arn:aws:bedrock:us-east-1:*:data-automation-project/*",
      "arn:aws:bedrock:us-east-1:*:data-automation-profile/*",
      "arn:aws:bedrock:us-east-2:*:data-automation-profile/*",
      "arn:aws:bedrock:us-west-1:*:data-automation-profile/*",
      "arn:aws:bedrock:us-west-2:*:data-automation-profile/*"
    ]
  }

  dynamic "statement" {
    for_each = var.enable_encryption ? [1] : []
    content {
      sid    = "KMSAccess"
      effect = "Allow"

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey"
      ]

      resources = [data.terraform_remote_state.keys.outputs.aws_kms_key_arn]
    }
  }
}

# Note: Bedrock Data Automation uses a service-linked role managed by AWS
# No custom IAM role needed for BDA project itself

resource "aws_iam_role" "lambda_execution_role" {
  name               = "${local.lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${local.lambda_function_name}-policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}