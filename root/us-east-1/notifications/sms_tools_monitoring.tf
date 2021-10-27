module "notify_costs" {
  source = "github.com/binbashar/terraform-aws-sns-topic.git?ref=0.19.2"

  name = var.sns_topic_name_costs

  subscribers = merge(
    {
      slack = {
        protocol               = "lambda"
        endpoint               = module.notify_slack_monitoring.notify_slack_lambda_function_arn
        endpoint_auto_confirms = true
        raw_message_delivery   = false
      }
    },
    {
      for v in ["phone1", "phone2", "phone3", "phone4", "phone5"] :
      v => {
        protocol               = "sms"
        endpoint               = data.vault_generic_secret.notifications.data[v]
        endpoint_auto_confirms = true
        raw_message_delivery   = false
      }
    }
  )

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
    resources = ["arn:aws:sns:${var.region}:${var.root_account_id}:${var.sns_topic_name_costs}"]
  }
}
