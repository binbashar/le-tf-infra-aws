#
# Cost Anomaly Detection
#
# The budgets and billing alarms above fire on an absolute monthly threshold. This
# fires on a *change in shape* -- a service whose spend departs from its own learned
# pattern -- which is what catches a misconfiguration days before it would breach a
# budget, and what catches a rate change on a service too small to move the total.
#
# A monitor created in the payer account evaluates the consolidated bill, so it covers
# every linked account without any Organizations trusted access of its own.
#
# Read from the management (payer) account by the `aws-finops` Claude Code plugin
# (`/aws-finops-investigate`, anomaly-triage phase) via `ce:GetAnomalyMonitors` and
# `ce:GetAnomalies`. Contrary to a common assumption, enabling Cost Explorer does *not*
# auto-create a monitor -- with none declared here the anomaly phase returns nothing.
#
# No `aws_ce_anomaly_subscription` yet, deliberately: anomaly alerts publish as
# `costalerts.amazonaws.com`, and the costs SNS topic
# (management/us-east-1/notifications) allows only `budgets.amazonaws.com` and is
# KMS-encrypted, so wiring it up needs both a topic-policy and a key-policy change.
# The plugin reads anomalies through the API and needs no subscription.
#
# Free of charge -- Cost Anomaly Detection has no cost, monitored or not.
#
resource "aws_ce_anomaly_monitor" "service" {
  name              = "${var.project}-${var.environment}-service-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = local.tags
}
