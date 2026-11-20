#
# Have any GuardDuty findings reported to a Slack channel
#
module "guardduty_monitor" {
  source = "github.com/binbashar/terraform-aws-guardduty-monitor?ref=v1.3.0"

  monitor_name                   = "default_guardduty_monitor"
  monitor_role_name              = "default_guardduty_monitor_role"
  event_rule_name                = "default_guardduty_monitor"
  monitor_slack_notification_url = data.aws_secretsmanager_secret_version.monitoring_security.secret_arn

  # Pinned while the layer was on AWS provider 5.x, which rejects the module's
  # nodejs24.x default (supported from 6.21.0). The layer is now on 6.x, so
  # dropping this pin moves the function to nodejs24.x (an in-place update).
  monitor_runtime = "nodejs22.x"
}

#
# The webhook secret lives in the shared account, encrypted with its KMS key.
# Reading it cross-account takes three grants: the secret's resource policy
# (shared/us-east-1/secrets-manager), the key policy (shared/us-east-1/security-keys)
# and this identity policy on the Lambda's role, which the module does not add.
#
resource "aws_iam_role_policy" "guardduty_monitor_kms" {
  name = "decrypt-shared-secrets"
  role = "default_guardduty_monitor_role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DecryptSharedSecretsViaSecretsManager"
      Effect   = "Allow"
      Action   = "kms:Decrypt"
      Resource = data.terraform_remote_state.shared_keys.outputs.aws_kms_key_arn
      Condition = {
        StringEquals = { "kms:ViaService" = "secretsmanager.${var.region}.amazonaws.com" }
      }
    }]
  })

  depends_on = [module.guardduty_monitor]
}
