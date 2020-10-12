#
# CONSIDERATION: To be considered
# https://trello.com/c/QOZ0aIGB/55-tf-modules-aws-backup-todo-issues
#
module "nightly_backups" {
  source = "github.com/binbashar/terraform-aws-backup-by-tags.git?ref=0.1.7"
  name   = "nightly_backups"
  tags   = local.tags
  selection_by_tags = {
    "Backup" = "True"
  }
  schedule     = "cron(0 5 * * ? *)"
  delete_after = 21
}
