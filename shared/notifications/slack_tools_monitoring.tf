# Encrypt the URL, storing encryption here will show it in logs and in tfstate
# https://www.terraform.io/docs/state/sensitive-data.html
data "aws_kms_ciphertext" "slack_url_monitoring" {
  plaintext = local.secrets.slack_webhook_monitoring
  key_id    = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}

#============================#
# AWS SNS -> Lambda -> Slack #
#============================#
# Set create_with_kms_key = true
# when providing value of kms_key_arn to create required IAM policy which allows to decrypt using specified KMS key.
module "notify_slack_monitoring" {
  source = "github.com/binbashar/terraform-aws-notify-slack.git?ref=v4.9.0"

  #
  # Creation Flags
  #
  create           = false
  create_sns_topic = false

  #
  # Slack Webhook URL + Channel
  #
  slack_channel     = "tools-monitoring"
  slack_username    = "aws-binbash-org"
  slack_webhook_url = data.aws_kms_ciphertext.slack_url_monitoring.ciphertext_blob

  kms_key_arn          = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
  lambda_function_name = "${var.project}-${var.environment}-notify-slack-monitoring"
  lambda_description   = "Lambda function which sends notifications to Slack"
  log_events           = false
  sns_topic_name       = var.sns_topic_name_monitoring

  cloudwatch_log_group_kms_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}
