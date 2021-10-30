module "notify_costs" {
  source = "github.com/binbashar/terraform-aws-sns-topic.git?ref=0.19.2"

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

  # Policy
  sns_topic_policy_json = join("", data.aws_iam_policy_document.aws_sns_topic_policy.*.json)

}

data "aws_iam_policy_document" "aws_sns_topic_policy" {

  policy_id = "SNSTopicsPub"
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
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
    resources = ["arn:aws:sns:${var.region}:${var.root_account_id}:${var.sns_topic_name_costs}"]
  }
}

#============================#
# AWS SNS -> Lambda -> Slack #
#============================#
# Set create_with_kms_key = true
# when providing value of kms_key_arn to create required IAM policy which allows to decrypt using specified KMS key.
module "notify_slack_monitoring_costs" {
  source = "github.com/binbashar/terraform-aws-notify-slack.git?ref=v4.15.0"

  #
  # Creation Flags
  #
  create           = true
  create_sns_topic = true

  #
  # Slack Webhook URL + Channel
  #
  slack_channel     = "le-tools-monitoring"
  slack_username    = "aws-binbash-org"
  slack_emoji       = ":AWS3:"
  slack_webhook_url = data.aws_kms_ciphertext.slack_url_monitoring.ciphertext_blob

  kms_key_arn          = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
  lambda_function_name = "${var.project}-${var.environment}-notify-slack-monitoring-costs"
  lambda_description   = "Lambda function which sends notifications to Slacki from the Cost Topic"
  log_events           = false
  sns_topic_name       = var.sns_topic_name_costs

  cloudwatch_log_group_kms_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}
