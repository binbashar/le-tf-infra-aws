# Cost Report Module - Quick Reference

This module deploys a Lambda function to fetch AWS cost data and post a daily report to Slack.

## Key Considerations

- **Lambda Source**: Uses `terraform-aws-lambda` (binbashar) module, with code in the `src/` directory.
- **Python Packaging**: The function has no third-party dependencies (standard library plus the runtime's bundled `boto3`), so there is no `requirements.txt` and the package is a plain zip of `src/` — applying needs neither Docker nor pip (`build_in_docker = false`). Adding a dependency would require building it in Docker again.
- **Slack Integration**: Requires a valid Slack webhook URL in the environment variables.
- **Permissions**: Lambda is granted only the minimum required permissions (`ce:GetCostAndUsage`, `ce:GetAnomalies`, `iam:ListAccountAliases`, `budgets:ViewBudget` on the one budget).
- **Scheduling**: Triggered daily at a configurable time via CloudWatch EventBridge rule (`var.report_run_schedule`).
- **Environment Variables**: Control report length, grouping, and Slack destination. Adjust as needed.
- **Logs**: CloudWatch logs are retained for 7 days.
- **Report window**: the 8 UTC days before the run — yesterday plus a 7-day baseline (the query reaches one day further back for the drop alerts). Yesterday is always flagged *partial* (dated, with a `*` on the `Yday*` column), because Cost Explorer has usually not finished billing it when the report runs at 12:00 UTC.
- **Table**: `∆$` and `∆%` compare yesterday with the average of the 7 days before it (`new` when there was nothing to compare with). Rows are the top `report_items_length` items by yesterday's cost, plus any item that moved by at least `report_mover_min_usd` — so a service that dropped to $0 is listed rather than hidden. Items under half a cent every day fold into `Other (N services)`, and the rows add up to `Total` (each figure is rounded to cents on its own, so the printed rows can differ from `Total` by a few cents). The footer states the cost metric and the excluded record types.
- **Month summary**: month to date against the same point last month (capped at that month's length), and the month-end pace — month to date plus the *median* of the last 7 complete days for each day left, so a once-a-month charge does not get projected onto every remaining day. One more Cost Explorer request (ungrouped daily totals since the start of last month). On the 1st the previous month is reported whole.
- **Budget**: `report_budget_name` (default: the 100% budget from `management/global/cost-mgmt`) is shown with AWS Budgets' own actual and forecast, labelled from the budget's CostTypes (tax, support, Marketplace, credits) since it may count charges the table excludes. Needs `budgets:ViewBudget`; if the budget cannot be read the report goes out without it.
- **Alerts**: an item alerts when it moved by both `report_alert_min_usd` (default $1) and `report_alert_min_pct` (default 30%) against a *typical day* — the median of the 7 days before, so a once-a-month charge alerts the day it lands but its absence afterwards is not a drop. Rises are judged on yesterday (partial, but a rise is real); drops on the day before yesterday, which is complete — so the query covers 9 days. A cost rising from nothing passes on the USD threshold alone. `report_alert_mention` (empty by default) is prepended to the alert list.
- **Anomalies**: open Cost Anomaly Detection anomalies — no feedback yet, ended in the last `report_anomaly_days` (default 14) days, impact ≥ `report_alert_min_usd` — are listed under the alerts with their root cause (region, linked account, usage type), and count in the verdict (`1 alert, 2 anomalies`). They stay until someone gives feedback in Cost Explorer › Anomaly detection, or age out of the window. One `GetAnomalies` request a day; if it fails the report goes out without the section. `0` turns it off.
- **Daily mode**: `report_daily_mode = "full"` (default) sends the full report every day, with the verdict in its header. `"compact"` sends a one-line message on quiet days instead (no table, so no view of the top services; it doubles as a heartbeat), and the full report when there are alerts, on `report_full_report_weekday` (default Monday), or on an invocation with `{"mode": "full"}`.
- **Slack message**: a Block Kit message — header, summary line, a `table` block and the footer as context. Service names are shortened (`S3`, `EC2 - Compute`, prefixes `Amazon `/`AWS ` dropped) unless that would make two rows identical. If Slack rejects the blocks, the function posts the plain-text report instead, so a layout error never loses the day's report. Teams and Google Chat get the plain-text report.
- **Scope**: run from the management (payer) account, Cost Explorer returns the whole Organization's bill; `REPORT_SCOPE` says so in the summary line.

## Testing

`src/` is the whole Lambda package, so tests live in `tests/` and are never deployed. From the repository root:

- `make cost-report-test` — offline tests against the synthetic Cost Explorer responses in `tests/fixtures/` (no AWS calls; the suite fails any test that tries).
- `make cost-report-preview` — builds the report from live Cost Explorer data with the management profile and prints it instead of posting to Slack. Each run is two or three billed requests ($0.02-0.03). It also checks the Block Kit message with Slack's public `blocks.validate` method and prints a Block Kit Builder link to preview it.

### Access to Slack Webhook Secret

- **Secret Storage**: The Slack webhook URL is stored securely in AWS Secrets Manager, not directly in Lambda environment variables. The secret is encrypted using a customer-managed KMS key (CMK).
- **IAM Permissions**: The Lambda function is granted permission to call `secretsmanager:GetSecretValue` on the specific secret ARN, and `kms:Decrypt` on the relevant KMS key, via inline policies in `main.tf`.
- **Runtime Retrieval**: At runtime, the Lambda reads the secret ARN from the `SLACK_WEBHOOK_SECRET_ID` environment variable and fetches the actual webhook URL using the AWS SDK (`boto3`).
- **Usage**: This approach ensures the Slack webhook URL is never exposed in plaintext in the Lambda configuration or logs, and can be rotated easily in Secrets Manager without redeploying the function. The use of a KMS CMK ensures that only authorized resources (like this Lambda) can decrypt and access the secret value.

> For advanced configuration or troubleshooting, review the comments in `main.tf`.
