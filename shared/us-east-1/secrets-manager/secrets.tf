module "secrets" {
  source = "github.com/binbashar/terraform-aws-secrets-manager.git?ref=0.6.0"

  secrets = {
    "/repositories/demo-google-microservices/deploy_key" = {
      description             = "Repository: Google Microservices DemoApp - Deploy Key"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },
    "/notifications/argocd" = {
      description             = "Slack App Oauth token for ArgoCD notifications"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },
    # "/notifications/alertmanager" = {
    #   description             = "Slack webhook for Alertmanager notifications"
    #   recovery_window_in_days = 7
    #   secret_string           = "INITIAL_VALUE"
    #   kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    # },
    # "/grafana/administrator" = {
    #   description             = "Credentials for Grafana administrator user"
    #   recovery_window_in_days = 7
    #   secret_string           = "INITIAL_VALUE"
    #   kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    # },

    #
    # This secret was created based on the centralized secrets approach and the naming conventions
    # defined here: https://binbash.atlassian.net/wiki/spaces/BDPS/pages/2425978910/Secrets+Management+Conventions
    #
    "/devops/notifications/slack/security" = {
      description             = "Slack Webhook for the security notifications"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },
  }

  tags = local.tags
}

data "aws_iam_policy_document" "secrets_policy" {
  statement {
    sid       = "ReadSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.accounts.shared.id}:role/DevOps",
        "arn:aws:iam::${var.accounts.data-science.id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DevOps_a1627cef3f7399d3",
      ]
    }
  }
}

resource "aws_secretsmanager_secret_policy" "secrets_policy" {
  for_each   = module.secrets.secret_arns
  secret_arn = each.value
  policy     = data.aws_iam_policy_document.secrets_policy.json
}
