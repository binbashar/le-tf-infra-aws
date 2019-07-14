#============================#
# AWS KMS: Key Mgmt Service  #
#============================#
resource "aws_kms_key" "root-org-key" {
  description         = "KMS key for notify-slack test"
  is_enabled          = true
  enable_key_rotation = true
  tags                = "${local.tags}"
}

resource "aws_kms_alias" "root-org-kms-alias" {
  name          = "alias/${var.project}-${var.environment}-kms-key"
  target_key_id = "${aws_kms_key.root-org-key.id}"
}

# Encrypt the URL, storing encryption here will show it in logs and in tfstate
# https://www.terraform.io/docs/state/sensitive-data.html
data "aws_kms_ciphertext" "slack_url" {
  plaintext = "${var.slack_webhook_url}"
  key_id    = "${aws_kms_key.root-org-key.arn}"
}

#============================#
# AWS SNS -> Lambda -> Slack #
#============================#
# Set create_with_kms_key = true
# when providing value of kms_key_arn to create required IAM policy which allows to decrypt using specified KMS key.
module "notify_slack" {
  source = "git::git@github.com:binbashar/terraform-aws-notify-slack.git?ref=v1.13.0"

  create               = true
  create_sns_topic     = true
  create_with_kms_key  = true
  kms_key_arn          = "${aws_kms_key.root-org-key.arn}"
  lambda_function_name = "${var.project}-${var.environment}-notify_slack"
  sns_topic_name       = "${var.sns_topic_name}"
  slack_webhook_url    = "${data.aws_kms_ciphertext.slack_url.ciphertext_blob}"
  slack_channel        = "${var.slack_channel}"
  slack_username       = "${var.slack_username}"
}

resource "aws_sns_topic_policy" "default" {
  arn = "${module.notify_slack.this_slack_topic_arn}"

  policy = "${data.aws_iam_policy_document.sns-topic-policy.json}"
}

data "aws_iam_policy_document" "sns-topic-policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "${var.root_org_account_id}",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }

    resources = [
      "${module.notify_slack.this_slack_topic_arn}",
    ]

    sid = "__default_statement_ID"
  }
}