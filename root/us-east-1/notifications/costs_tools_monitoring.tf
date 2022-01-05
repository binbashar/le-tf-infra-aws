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

  # Access policy document
  sns_topic_policy_json = join("", data.aws_iam_policy_document.aws_sns_topic_policy.*.json)

}

# Subscribing a list of email addresses to SNS topic
resource "aws_sns_topic_subscription" "topic_email_subscription" {
  count                   = length(var.costs_email_addresses)
  topic_arn               = module.notify_costs.sns_topic_arn
  endpoint_auto_confirms  = true
  protocol                = "email"
  endpoint                = var.costs_email_addresses[count.index]
}

# Access policy document
data "aws_iam_policy_document" "aws_sns_topic_policy" {

  policy_id = "SNSTopicsPub"
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    sid = "_default"
    effect = "Allow"
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission"
    ]
    resources = [module.notify_costs.sns_topic_arn]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }
    sid = "_budgets_service_access_ID"
    actions = [
      "SNS:Publish",
    ]
    effect = "Allow"
    resources = [module.notify_costs.sns_topic_arn]
  }
}

#============================#
# AWS SNS -> Lambda -> Slack #
#============================#
# Set create_with_kms_key = true
# when providing value of kms_key_arn to create required IAM policy which allows to decrypt using specified KMS key.
module "notify_slack_monitoring_costs" {
  source = "github.com/binbashar/terraform-aws-notify-slack.git?ref=v4.24.0"

  #
  # Creation Flags
  #
  create           = true
  create_sns_topic = false

  #
  # Slack Webhook URL + Channel
  #
  slack_channel     = "le-tools-monitoring"
  slack_username    = "aws-binbash-org"
  slack_emoji       = ":AWS3:"
  slack_webhook_url = data.aws_kms_ciphertext.slack_url_monitoring.ciphertext_blob

  kms_key_arn          = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
  lambda_function_name = "${var.project}-${var.environment}-notify-slack-monitoring-costs"
  lambda_description   = "Lambda function which sends notifications to Slack from the Costs Topic"
  log_events           = false
  sns_topic_name       = var.sns_topic_name_costs

  cloudwatch_log_group_kms_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}
