# Encrypt the URL, storing encryption here will show it in logs and in tfstate
# https://www.terraform.io/docs/state/sensitive-data.html
data "aws_kms_ciphertext" "slack_url_bb_monitoring" {
  plaintext = "https://hooks.slack.com/services/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"
  key_id    = data.terraform_remote_state.security.outputs.aws_kms_key_arn
}

#============================#
# AWS SNS -> Lambda -> Slack #
#============================#
# Set create_with_kms_key = true
# when providing value of kms_key_arn to create required IAM policy which allows to decrypt using specified KMS key.
module "notify_slack_bb_monitoring" {
  source = "github.com/binbashar/terraform-aws-notify-slack.git?ref=v3.3.0"

  #
  # Creation Flags
  #
  create           = true
  create_sns_topic = true

  #
  # Slack Webhook URL + Channel
  #
  slack_channel     = "tools-monitoring"
  slack_username    = "aws-binbash-org"
  slack_webhook_url = data.aws_kms_ciphertext.slack_url_bb_monitoring.ciphertext_blob

  kms_key_arn          = data.terraform_remote_state.security.outputs.aws_kms_key_arn
  lambda_function_name = "${var.project}-${var.environment}-notify-slack-bb-monitoring"
  lambda_description   = "Lambda function which sends notifications to Slack"
  log_events           = false
  sns_topic_name       = var.sns_topic_name_bb_monitoring
}
