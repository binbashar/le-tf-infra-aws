#
# SNS Topic with SMS subscriptions
#
module "notify_costs" {
  source = "github.com/binbashar/terraform-aws-sns-topic.git?ref=0.20.1"

  name = var.sns_topic_name_costs

  subscribers = {
    for v in ["phone1", "phone2", "phone3", "phone4", "phone5"] :
    v => {
      protocol               = "sms"
      endpoint               = data.vault_generic_secret.notifications.data[v]
      endpoint_auto_confirms = true
      raw_message_delivery   = false
    }
  }

  kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}

# Subscribing a list of email addresses to SNS topic
resource "aws_sns_topic_subscription" "topic_email_subscription" {
  count                  = length(var.costs_email_addresses)
  topic_arn              = module.notify_costs.sns_topic_arn
  endpoint_auto_confirms = true
  protocol               = "email"
  endpoint               = var.costs_email_addresses[count.index]
}

resource "aws_sns_topic_policy" "sns-notify-costs" {
  arn = module.notify_costs.sns_topic_arn

  policy = data.aws_iam_policy_document.sns-notify-costs.json
}

# Access policy document
data "aws_iam_policy_document" "sns-notify-costs" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }

    resources = [
      module.notify_costs.sns_topic_arn,
    ]

    sid = "_budgets_service_access_ID"
  }

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
        var.accounts.root.id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      module.notify_costs.sns_topic_arn,
    ]

    sid = "__default_statement_ID"
  }
}

#============================#
# AWS SNS -> Lambda -> Slack #
#============================#
# Encrypt the URL, storing encryption here will show it in logs and in tfstate
# https://www.terraform.io/docs/state/sensitive-data.html
resource "aws_kms_ciphertext" "slack_url_monitoring_costs" {
  plaintext = data.vault_generic_secret.notifications.data["slack_webhook_monitoring_costs"]
  key_id    = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}

# Set create_with_kms_key = true
# when providing value of kms_key_arn to create required IAM policy which allows to decrypt using specified KMS key.
module "notify_slack_monitoring_costs" {
  source = "github.com/binbashar/terraform-aws-notify-slack.git?ref=v5.6.0"

  #
  # Creation Flags
  #
  create           = true
  create_sns_topic = false

  #
  # Slack Webhook URL + Channel
  #
  slack_channel     = "le-tools-monitoring-costs"
  slack_username    = "leverops-aws-costs"
  slack_emoji       = ":AWS3:"
  slack_webhook_url = aws_kms_ciphertext.slack_url_monitoring_costs.ciphertext_blob

  kms_key_arn          = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
  lambda_function_name = "${var.project}-${var.environment}-notify-slack-monitoring-costs"
  lambda_description   = "Lambda function which sends notifications to Slack from the Costs Topic"
  log_events           = false
  sns_topic_name       = var.sns_topic_name_costs

  cloudwatch_log_group_kms_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}
