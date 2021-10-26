module "notify_sms" {
  source = "github.com/binbashar/terraform-aws-sns-topic.git?ref=0.19.2"

  name = var.sns_topic_name_sms

  subscribers = {
    phone1 = {
      protocol               = "sms"
      endpoint               = data.vault_generic_secret.notifications.data["phone1"]
      endpoint_auto_confirms = true
      raw_message_delivery   = false
    }
    #phone2 = {
    #  protocol               = "sms"
    #  endpoint               = data.vault_generic_secret.notifications.data["phone2"]
    #  endpoint_auto_confirms = true
    #  raw_message_delivery   = false
    #}
    #phone3 = {
    #  protocol               = "sms"
    #  endpoint               = data.vault_generic_secret.notifications.data["phone3"]
    #  endpoint_auto_confirms = true
    #  raw_message_delivery   = false
    #}
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
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["arn:aws:sns:${var.region}:${var.root_account_id}:${var.sns_topic_name_sms}"]
  }
}
