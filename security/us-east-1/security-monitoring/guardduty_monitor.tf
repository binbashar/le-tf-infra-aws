#
# Have any GuardDuty findings reported to a Slack channel
#
module "guardduty_monitor" {
  source = "github.com/binbashar/terraform-aws-guardduty-monitor?ref=v1.2.1"

  monitor_name                   = "default_guardduty_monitor"
  monitor_role_name              = "default_guardduty_monitor_role"
  event_rule_name                = "default_guardduty_monitor"
  monitor_slack_notification_url = data.vault_generic_secret.slack_hook_url_monitoring.data["slack_webhook_monitoring_sec"]
}
