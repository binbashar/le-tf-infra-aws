module "secrets" {
  source = "github.com/binbashar/terraform-aws-secrets-manager.git?ref=0.6.0"

  secrets = {
    "/repositories/demo-google-microservices/deploy_key" = {
      description             = "Repository: Google Microservices DemoApp - Deploy Key"
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
        "arn:aws:iam::${var.accounts.shared.id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DevOps_40ba147128d7f4be",
      ]
    }
  }
}

resource "aws_secretsmanager_secret_policy" "secrets_policy" {
  for_each   = module.secrets.secret_arns
  secret_arn = each.value
  policy     = data.aws_iam_policy_document.secrets_policy.json
}
