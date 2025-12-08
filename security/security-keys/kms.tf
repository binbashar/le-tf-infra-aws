module "kms_key" {
  for_each = toset(var.regions)
  providers = {
    aws = aws.by_region[each.key]
  }
  source = "github.com/binbashar/terraform-aws-kms-key.git?ref=0.12.2"

  enabled                 = var.kms_settings.enabled
  namespace               = var.project
  stage                   = var.environment
  name                    = var.kms_settings.key_name
  delimiter               = var.kms_settings.delimiter
  description             = var.kms_settings.description
  deletion_window_in_days = var.kms_settings.deletion_window_in_days
  enable_key_rotation     = var.kms_settings.enable_key_rotation
  alias                   = "alias/${var.project}_${var.environment}_${var.kms_settings.key_name}_key"
  policy                  = data.aws_iam_policy_document.kms.json
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "Grant full access to the owner account"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.accounts.security.id}:root"]
    }
  }

  statement {
    sid    = "Grant usage permissions to CloudTrail"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com",
        "cloudwatch.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = [
        "arn:aws:cloudtrail::${var.accounts.security.id}:trail/${var.project}-${var.environment}-cloudtrail-org"
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
      identifiers = ["logs.*.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs::${var.accounts.security.id}:*"]
    }
  }

  # statement {
  #   sid    = "Allow Wazuh to decrypt CloudTrail bucket objects"
  #   effect = "Allow"
  #   actions = [
  #     "kms:Decrypt*",
  #     "kms:GenerateDataKey*",
  #   ]
  #   resources = ["*"]

  #   principals {
  #     type        = "AWS"
  #     identifiers = ["arn:aws:iam::${var.accounts.security.id}:role/Wazuh"]
  #   }
  #   condition {
  #     test     = "ArnLike"
  #     variable = "kms:EncryptionContext:aws:s3:arn"
  #     values   = ["arn:aws:s3:::bb-security-cloudtrail-org"]
  #   }
  # }
}
