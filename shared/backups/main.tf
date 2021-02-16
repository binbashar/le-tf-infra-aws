#
# Run daily backups on tagged resources
#
module "daily_backups_tagged_resources" {
  source = "github.com/binbashar/terraform-aws-backup.git?ref=0.6.0"

  # Backup vaults are containers where your backups are stored. You can specify
  # a new one to be created by this module or omit it to use the default one.
  vault_name = local.vault_name

  # Backup plans define your backup requirements, including backup schedules,
  # backup retention rules and lifecycle rules.
  plan_name = "daily-backups"

  # Backup rules that define when to run them, start/completion tolerance,
  # lifecycle, and more.
  rules = [
    {
      name              = "daily-runs"
      schedule          = "cron(0 20 * * ? *)"
      target_vault_name = null
      start_window      = 120
      completion_window = 360
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 7
      },
      recovery_point_tags = {
        Backup = "True"
      }
    },
  ]

  # We use tags to select which resources should be backed up. We could also
  # use more specific rules that select by ARN or match pattern.
  selections = [
    {
      name = "tagged-resources"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Backup"
        value = "True"
      }
    },
  ]

  tags = local.tags
}

module "daily_backups_notifications" {
  source = "github.com/binbashar/terraform-aws-backup-notifications.git?ref=0.0.1"

  enabled           = true
  backup_vault_name = local.vault_name
  backup_vault_events = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_FAILED",
    "BACKUP_JOB_SUCCESSFUL",
  ]

  # You can either pass the ARN of an existing SNS Topic
  sns_topic_arn = data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring_sec

  # Or have the module create a new SNS Topic to which the following subscriptors will be attached
  topic_subscriptions = {
    # notify_slack = {
    #   protocol               = "lambda"
    #   endpoint               = data.terraform_remote_state.notifications.outputs.notify_slack_monitoring_sec_lambda_function_arn_monitoring_sec
    #   endpoint_auto_confirms = true
    #   raw_message_delivery   = true
    # }
  }
}
