#
# Have any GuardDuty findings reported to a Slack channel
#
module "guardduty_monitor" {
  source = "github.com/binbashar/terraform-aws-guardduty-monitor?ref=v1.3.0"

  monitor_name                   = "default_guardduty_monitor"
  monitor_role_name              = "default_guardduty_monitor_role"
  event_rule_name                = "default_guardduty_monitor"
  monitor_slack_notification_url = data.aws_secretsmanager_secret_version.monitoring_security.arn

  # The module defaults to nodejs24.x, which needs AWS provider >= 6.21.0; this
  # layer is on ~> 5.0. Move to nodejs24.x when the layer moves to provider 6.x.
  monitor_runtime = "nodejs22.x"
}
