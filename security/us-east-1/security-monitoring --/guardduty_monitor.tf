#
# Have any GuardDuty findings reported to a Slack channel
#
module "guardduty_monitor" {
  source = "github.com/binbashar/terraform-aws-guardduty-monitor?ref=v1.2.1"

  monitor_name                   = "default_guardduty_monitor"
  monitor_role_name              = "default_guardduty_monitor_role"
  event_rule_name                = "default_guardduty_monitor"
  monitor_slack_notification_url = data.aws_secretsmanager_secret_version.monitoring_security.arn
}
