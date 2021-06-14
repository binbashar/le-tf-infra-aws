module "kms_key" {
  source = "github.com/binbashar/terraform-aws-kms-key.git?ref=0.10.0"

  enabled                 = true
  namespace               = var.project
  stage                   = var.environment
  name                    = var.kms_key_name
  delimiter               = "-"
  description             = "KMS key for ${var.project}-${var.environment} Account"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  alias                   = "alias/${var.project}_${var.environment}_${var.kms_key_name}_key"
  policy                  = data.aws_iam_policy_document.kms.json
  tags                    = local.tags
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.security_account_id}:root"]
    }
  }

  statement {
    sid    = "Enable CloudTrail Service"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = [
        "arn:aws:cloudtrail:*:${var.security_account_id}:trail/*",
        "arn:aws:cloudtrail:*:${var.shared_account_id}:trail/*",
        "arn:aws:cloudtrail:*:${var.root_account_id}:trail/*",
        "arn:aws:cloudtrail:*:${var.appsdevstg_account_id}:trail/*",
        "arn:aws:cloudtrail:*:${var.appsprd_account_id}:trail/*"
      ]
    }
  }

  statement {
    sid    = "Enable CloudWatch Logs Service"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.region}:${var.security_account_id}:*"]
    }
  }
}
