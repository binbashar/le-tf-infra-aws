module "kms_key" {
  source = "github.com/binbashar/terraform-aws-kms-key.git?ref=0.12.2"

  enabled                 = true
  namespace               = var.project
  stage                   = var.environment
  name                    = var.kms_key_name
  delimiter               = "-"
  description             = "KMS key for ${var.environment} Account"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  alias                   = "alias/${var.project}_${var.environment}_${var.kms_key_name}_key"
  policy                  = data.aws_iam_policy_document.kms.json
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.accounts.shared.id}:root"]
    }
  }

  statement {
    sid    = "Grant read-only to other accounts that use the key with Secrets Manager"
    effect = "Allow"
    actions = [
      "kms:Decrypt*",
      "kms:Describe*"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.accounts.data-science.id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DevOps_a1627cef3f7399d3",
        # Cost Report lambda function
        "arn:aws:iam::${var.accounts.management.id}:role/bb-root-cost-report"
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
      values   = ["arn:aws:logs:${var.region}:${var.accounts.shared.id}:*"]
    }
  }
}
