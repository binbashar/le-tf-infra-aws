module "secrets" {
  source  = "github.com/binbashar/terraform-aws-secrets-manager.git?ref=0.11.5"
  secrets = local.secrets
  tags    = local.tags
}

# The following policy is the one shared by all secrets
data "aws_iam_policy_document" "secrets_policy" {
  statement {
    sid    = "ReadSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:GetResourcePolicy",
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        # Delegate control to the owner account; which happens by default but I couldn't leave this
        # identifiers list empty
        "arn:aws:iam::${var.accounts.shared.id}:root"

        # Add below only cross-account (or cross-region) roles that require read access to all secrets.
        # For instance, SSO roles or IAM entities in this account shouldn't need that.
        # Important: you will also have to update the KMS key that is used to encrypt the secrets
        # E.g. "arn:aws:iam::some-account:role/some-special-tool-that-requires-this-much-access"
      ]
    }
  }
}

# Create a merged policy for each secret, it should combine the shared policy
# with the optional-custom one (if defined)
data "aws_iam_policy_document" "merged_secret_policy" {
  for_each = module.secrets.secret_arns

  source_policy_documents = [data.aws_iam_policy_document.secrets_policy.json]

  dynamic "statement" {
    for_each = (
      contains(keys(local.secrets[each.key]), "custom_policy_json") ? [local.secrets[each.key].custom_policy_json] : []
    )
    content {
      sid       = statement.value.sid
      actions   = statement.value.actions
      resources = statement.value.resources
      effect    = statement.value.effect

      dynamic "principals" {
        for_each = contains(keys(statement.value), "principal") ? [statement.value.principal] : []
        content {
          type        = "AWS"
          identifiers = [principals.value.AWS]
        }
      }
    }
  }
}

# Assign the combined policy to each secret
resource "aws_secretsmanager_secret_policy" "secrets_policy" {
  for_each   = module.secrets.secret_arns
  secret_arn = each.value
  policy     = data.aws_iam_policy_document.merged_secret_policy[each.key].json
}
