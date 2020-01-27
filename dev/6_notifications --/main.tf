# Encrypt the URL, storing encryption here will show it in logs and in tfstate
# https://www.terraform.io/docs/state/sensitive-data.html
data "aws_kms_ciphertext" "slack_url" {
  plaintext = var.slack_webhook_url
  key_id    = data.terraform_remote_state.security.outputs.aws_kms_key_arn
}

#============================#
# AWS SNS -> Lambda -> Slack #
#============================#
# Set create_with_kms_key = true
# when providing value of kms_key_arn to create required IAM policy which allows to decrypt using specified KMS key.
module "notify_slack" {
  source = "git::git@github.com:binbashar/terraform-aws-notify-slack.git?ref=v2.9.0"

  create               = true
  create_sns_topic     = true
  kms_key_arn          = data.terraform_remote_state.security.outputs.aws_kms_key_arn
  lambda_function_name = "${var.project}-${var.environment}-notify_slack"
  sns_topic_name       = var.sns_topic_name
  slack_webhook_url    = data.aws_kms_ciphertext.slack_url.ciphertext_blob
  slack_channel        = var.slack_channel
  slack_username       = var.slack_username
}