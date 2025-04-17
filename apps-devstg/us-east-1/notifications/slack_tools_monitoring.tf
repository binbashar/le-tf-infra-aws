# Encrypt the URL, storing encryption here will show it in logs and in tfstate
# https://www.terraform.io/docs/state/sensitive-data.html

resource "aws_kms_ciphertext" "slack_url_monitoring" {
  plaintext = data.sops_file.secrets.data["slack_webhook_monitoring"]
  key_id    = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}



#============================#
# AWS SNS -> Lambda -> Slack #
#============================#
# Set create_with_kms_key = true
# when providing value of kms_key_arn to create required IAM policy which allows to decrypt using specified KMS key.
module "notify_slack_monitoring" {
  source = "github.com/binbashar/terraform-aws-notify-slack.git?ref=v5.6.0"

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
  slack_webhook_url = aws_kms_ciphertext.slack_url_monitoring.ciphertext_blob

  kms_key_arn          = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
  lambda_function_name = "${var.project}-${var.environment}-notify-slack-monitoring"
  lambda_description   = "Lambda function which sends notifications to Slack"
  log_events           = false
  sns_topic_name       = var.sns_topic_name_monitoring

  cloudwatch_log_group_kms_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}

# ##################################################################################
# permisssions for budget->sns topic publication
data "aws_caller_identity" "current" {}

resource "aws_sns_topic_policy" "default" {
  count  = var.add_budget_service_permission == true ? 1 : 0
  arn    = module.notify_slack_monitoring.slack_topic_arn
  policy = data.aws_iam_policy_document.sns-topic-policy[0].json
}

data "aws_iam_policy_document" "sns-topic-policy" {
  count = var.add_budget_service_permission == true ? 1 : 0

  policy_id = "publish_to_topic_policy"

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
        data.aws_caller_identity.current.account_id
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      module.notify_slack_monitoring.slack_topic_arn
    ]

    sid = "__default_statement_ID"
  }
}
