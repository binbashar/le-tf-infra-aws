module "secrets" {
  source = "github.com/binbashar/terraform-aws-secrets-manager.git?ref=0.11.5"

  secrets = {
    "/k8s-eks-demoapps/test-secrets" = {
      description             = "DemoApps SecretManager Test Secret"
      recovery_window_in_days = 7
      secret_string           = "PLACEHOLDER"
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
        "arn:aws:iam::${var.accounts.apps-devstg.id}:role/DevOps",
        "arn:aws:iam::${var.accounts.management.id}:role/OrganizationAccountAccessRole"
      ]

    }
  }
}

resource "aws_secretsmanager_secret_policy" "secrets_policy" {
  for_each   = module.secrets.secret_arns
  secret_arn = each.value
  policy     = data.aws_iam_policy_document.secret_policy.json
}
