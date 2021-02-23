#
# Enable Cross-account Backups
#
resource "aws_backup_global_settings" "default" {
  global_settings = {
    "isCrossAccountBackupEnabled" = "true"
  }
}
