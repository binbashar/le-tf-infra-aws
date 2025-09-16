module "secrets" {
  source = "github.com/binbashar/terraform-aws-secrets-manager.git?ref=0.11.5"

  # Test change to trigger AI validation workflow - Reverted to working GPT-4o model
  secrets = {
    # NOTE: Fields annotated with "#@" must be commented out in the first step, when the database is not yet deployed
    # Update the secret to a secure password via web console after applying
    # Re-apply after db instance is created
    "/aurora-pgsql/administrator" = {
      description             = "Apps-devstg Aurora Postgres cluster database administrator"
      recovery_window_in_days = 7
      secret_key_value = {
        # engine   = data.terraform_remote_state.apps-devstg-aurora-pgsql.outputs.cluster_engine, #@
        # host     = data.terraform_remote_state.apps-devstg-aurora-pgsql.outputs.cluster_endpoint,   #@
        username = "administrator",
        password = "alreadyRotatedPassword",
        # dbname   = data.terraform_remote_state.apps-devstg-aurora-pgsql.outputs.cluster_database_name, #@
        # port     = data.terraform_remote_state.apps-devstg-aurora-pgsql.outputs.cluster_port  #@
      }
      kms_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_id,
      # https://github.com/binbashar/terraform-aws-secrets-manager#secrets-rotation
      # rotation_lambda_arn     = "arn:aws:lambda:us-east-1:xxxxxxxxxxxx:function:lambda-rotate-secret"
    },
    "/pgsql/administrator" = {
      description             = "Apps-devstg Postgres database administrator"
      recovery_window_in_days = 7
      secret_key_value = {
        # engine   = data.terraform_remote_state.apps-devstg-pgsql.outputs.cluster_engine, #@
        # host     = data.terraform_remote_state.apps-devstg-pgsql.outputs.cluster_endpoint,   #@
        username = "administrator",
        password = "alreadyRotatedPassword",
        # dbname   = data.terraform_remote_state.apps-devstg-pgsql.outputs.cluster_database_name, #@
        # port     = data.terraform_remote_state.apps-devstg-pgsql.outputs.cluster_port  #@
      }
      kms_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_id,
      # https://github.com/binbashar/terraform-aws-secrets-manager#secrets-rotation
      # rotation_lambda_arn     = "arn:aws:lambda:us-east-1:xxxxxxxxxxxx:function:lambda-rotate-secret"
    }
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
