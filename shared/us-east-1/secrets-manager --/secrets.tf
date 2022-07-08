module "secrets" {
  source = "github.com/binbashar/terraform-aws-secrets-manager.git?ref=0.5.1"

  secrets = {
    "/notifications/slack/webhook_url_monitoring" = {
      description             = "Slack hook url for the monitoring channel"
      recovery_window_in_days = 7
      secret_string           = "https:/slack_demo.org/monitoring"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },
    "/notifications/slack/webhook_url_monitoring_sec" = {
      description             = "Slack hook url the monitoring_sec channel"
      recovery_window_in_days = 7
      secret_string           = "https:/slack_demo.org/monitoring_sec"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },
    "/notifications/slack/webhook_url_monitoring_costs" = {
      description             = "Slack hook urlfor the cost channel"
      recovery_window_in_days = 7
      secret_string           = "https:/slack_demo.org/costs"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },
  }

  tags = local.tags

}

# Set secrets policies
data "aws_iam_policy_document" "secret_policy" {
  statement {
    sid       = "GetSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.shared_account_id}:role/DevOps",
        "arn:aws:iam::${var.appsdevstg_account_id}:role/DevOps",
        "arn:aws:iam::${var.appsprd_account_id}:role/DevOps",
        "arn:aws:iam::${var.accounts.security.id}:role/DevOps",
        "arn:aws:iam::${var.accounts.root.id}:role/OrganizationAccountAccessRole"
      ]

    }
  }
}

resource "aws_secretsmanager_secret_policy" "secrets_policy" {
  for_each   = module.secrets.secret_arns
  secret_arn = each.value
  policy     = data.aws_iam_policy_document.secret_policy.json
}

