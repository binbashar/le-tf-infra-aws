# Cost Management - Quick Reference

Account-level cost **governance** for the management (payer) account: alarms and budgets
that fire on spend, plus the anomaly monitor that fires on a change in spend *shape*.

Because this is the payer account, everything here sees the **consolidated bill** — every
linked account's spend is already included, with no per-account setup.

## What's in here

| Resource | What it does |
| --- | --- |
| `module.aws_cost_mgmt_billing_alert_50` / `_100` | CloudWatch billing alarms at fixed USD thresholds |
| `module.aws_cost_mgmt_budget_notif_75` / `_100` | AWS Budgets notifications at 75% / 100% of the monthly limit |
| `aws_ce_anomaly_monitor.service` | Cost Anomaly Detection, `DIMENSIONAL` on `SERVICE` |

## Key Considerations

- **Alarms and budgets answer a different question than the anomaly monitor.** The first two
  fire on an *absolute monthly threshold*. The monitor fires when a service departs from its
  own learned pattern — which is what catches a misconfiguration days before it would breach
  a budget, and what catches a rate change on a service too small to move the total.
- **Enabling Cost Explorer does *not* create a default anomaly monitor.** This is a common
  assumption and it is wrong; `ce:GetAnomalyMonitors` returned zero on this account before
  `aws_ce_anomaly_monitor.service` was added. With no monitor declared, anomaly data simply
  does not exist.
- **New monitors are not instantly useful.** AWS needs roughly **10 days** of history to learn
  a service's pattern before it will call anything anomalous. A report run right after this
  applies will legitimately come back empty.
- **No `aws_ce_anomaly_subscription`, on purpose.** Anomaly alerts publish as
  `costalerts.amazonaws.com`, but the costs SNS topic in
  [`management/us-east-1/notifications`](../../us-east-1/notifications) allows only
  `budgets.amazonaws.com` and is KMS-encrypted — so alerting needs both a topic-policy and a
  key-policy change in other layers. Anomalies are still readable through
  `ce:GetAnomalies`; nothing is lost except a push notification.
- **Notifications come from another layer.** The alarms and budgets publish to the costs SNS
  topic read from `data.terraform_remote_state.notifications`. Changing who gets paged is a
  change in `management/us-east-1/notifications`, not here.
- **Provider is pinned `aws ~> 5.0`.** `aws_ce_anomaly_monitor` needs `>= 4.19`; the layer was
  on `~> 3.0` until then. The two binbash cost modules only require `>= 2.70.0`, so the pin is
  this layer's own choice, not a module constraint.

## Who reads this data

The [`aws-finops`](../../../docs/finops/README.md) Claude Code plugin reads the monitor
(`/aws-finops-investigate`, anomaly-triage phase) from the management account via the
`awslabs.billing-cost-management-mcp-server` MCP server.

Compute Optimizer and the Cost Optimization Hub — the other half of what that plugin reads —
are **org-wide** enrollments and live in
[`management/global/organizations`](../organizations) instead.

> Distinct from `management/global/cost-report`, which posts a daily Slack digest, and from
> `make infracost-breakdown`, which prices a *proposed* change. This layer is about money
> already spent.
