module "nightly_backups" {
  source = "github.com/binbashar/terraform-aws-backup.git?ref=v0.24.0"

  # Plan
  plan_name = "nightly_backups"

  # Multiple rules using a list of maps
  rules = [
    {
      name                     = "rule-1"
      schedule                 = "cron(0 5 * * ? *)"
      target_vault_name        = "Default"
      start_window             = 120
      completion_window        = 360
      enable_continuous_backup = true
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 21
      }
    }
  ]

  # Selection by tags
  selections = [
    {
      name = "selection-by-tags"
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Backup"
          value = "True"
        }
      ]
    }
  ]

  tags = local.tags
}
