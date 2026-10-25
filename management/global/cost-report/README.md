# Cost Report

A Lambda function that posts a daily AWS cost report to Slack. It runs in the management (payer) account, where Cost Explorer returns the whole Organization's bill.

- [How to read the report](#how-to-read-the-report) — for everyone who receives it
- [Architecture](#architecture) — how it works
- [Installation](#installation) — how to deploy it
- [Usage](#usage) — configuration, testing and operations

## How to read the report

The report arrives every day as one Slack message, with the details in its thread.

### The message

- **Header**: the day reported and the verdict. :white_check_mark: means nothing needs attention; :warning: counts the alerts and anomalies (`1 alert, 2 anomalies`).
- **Yesterday**: the total cost yesterday and how it compares with the average of the 7 days before it.
- **The month** (e.g. *October*): the month so far, the change against the same point last month, and where the month is heading. The pace adds, for each remaining day, the *median* of the last 7 days, so a once-a-month charge is not projected onto every remaining day. **Budget** is the AWS Budget's own figures, which also count tax, support, upfront fees and Marketplace subscriptions — so it can be higher than the table. :warning: means it is over its limit.
- **Alerts** (only when there are any): a service whose cost moved by at least **$1 and 30%** (the default thresholds) against a typical day (the median of the 7 days before). Rises are judged on yesterday; drops on the day before yesterday, because yesterday is still incomplete.
- **Anomalies** (only when there are any): how many open anomalies Cost Anomaly Detection found. The list is in the thread.
- **Top services**: the services that cost the most yesterday, plus any service that moved by $0.50 or more — so a service that dropped to $0 is listed rather than hidden.

### The table

| Column | Meaning |
|---|---|
| `Yday*` | Yesterday's cost. The `*` means *partial*: Cost Explorer usually keeps adding charges for a day after the report runs, so the final figure tends to be higher. |
| `∆$`, `∆%` | Yesterday against the average of the 7 days before it. `new`: no cost in those days to compare with. |
| `Last 7d` | The last 7 days as a sparkline, oldest first. |
| `Other (N services)` | Services under half a cent every day, folded together. |
| `Total` | Every row added up. Each figure is rounded to cents on its own, so the rows can differ from `Total` by a few cents. |

Costs are **unblended**, and exclude credits, refunds, upfront fees and support.

### The thread

- **Anomalies**: each open anomaly with its date, impact and root cause (region, account, usage type). An anomaly stays listed until someone gives feedback on it in *Cost Explorer › Anomaly detection*, or until it is 14 days old.
- **Alert breakdown**: for each alert, the accounts and usage types that moved the most.
- **By account**: the same table as the message, with one row per account.

## Architecture

```text
EventBridge (daily, 12:00 UTC)
  └─> Lambda bb-management-cost-report (management account)
        ├─ Cost Explorer: GetCostAndUsage (by service, monthly totals, by account, alert breakdowns), GetAnomalies
        ├─ AWS Budgets: DescribeBudget
        ├─ Secrets Manager (shared account): Slack bot token, Slack webhook URL
        └─> Slack: chat.postMessage (report + thread reply); the webhook if the bot cannot post
CloudWatch alarm on the Lambda's Errors ──> SNS sns-topic-costs
```

- **Code**: `src/handler.py`, deployed with the `terraform-aws-lambda` module. It uses only the Python standard library plus the runtime's bundled `boto3`, so the package is a plain zip of `src/` (`build_in_docker = false`). There is no `requirements.txt`: adding a dependency would need Docker builds again.
- **Slack**: a Slack app's bot (`chat:write`) posts the report with `chat.postMessage`. That call returns the message's `ts`, which lets the bot reply in the thread. The incoming webhook is the fallback when there is no bot or it cannot post (token revoked, bot removed from the channel). The report then still goes out, with everything in one message and no thread. If Slack rejects a message's blocks, it is sent again as plain text. Teams and Google Chat webhooks get the plain-text report.
- **Secrets**: both Slack secrets live in `shared/us-east-1/secrets-manager`, encrypted with the shared account's KMS key. Their resource policies allow this Lambda's role. The Lambda reads them at runtime from `SLACK_BOT_TOKEN_SECRET_ID` and `SLACK_WEBHOOK_SECRET_ID`; neither value is in this repository or in the Lambda's configuration.
- **Permissions**: `ce:GetCostAndUsage`, `ce:GetAnomalies` and `iam:ListAccountAliases`; `budgets:ViewBudget` on the one budget; `secretsmanager:GetSecretValue` and `kms:Decrypt` for the Slack secrets.
- **Resilience**: the budget, anomalies, cost by account and alert breakdowns are optional. Each one uses fail-fast timeouts, and if it fails the report goes out without that part. Breakdowns stop when fewer than 20 s of the Lambda's 60 s remain. A failed run triggers the `bb-management-cost-report-errors` alarm.
- **Cost**: three or four Cost Explorer requests a day ($0.01 each per page), plus one per alert broken down, on alert days only.

## Installation

1. **Slack app** (once, by a Slack workspace admin):
   1. At <https://api.slack.com/apps>, choose *Create New App → From a manifest*, pick the workspace and paste:
      ```yaml
      display_information:
        name: AWS Cost Report
      features:
        bot_user:
          display_name: AWS Cost Report
      oauth_config:
        scopes:
          bot:
            - chat:write
      settings:
        token_rotation_enabled: false
      ```
   2. *Install App → Install to Workspace*, then copy the *Bot User OAuth Token* (`xoxb-…`).
   3. In the report's channel: `/invite @AWS Cost Report`. Copy the channel ID from the channel's *About* tab.
2. **Secrets**: apply `shared/us-east-1/secrets-manager`, which creates `/notifications/slack/cost-reports-bot` with a placeholder value. Then set the token by hand, from a shell with the shared account's profile:
   ```bash
   read -rs TOKEN && aws secretsmanager put-secret-value \
     --secret-id /notifications/slack/cost-reports-bot --secret-string "$TOKEN"
   ```
   The webhook secret, `/notifications/slack/cost-reports`, is set the same way.
3. **Lambda**: set `report_slack_channel_id` in `variables.tf`, then run `leverage tofu apply` from this layer.
4. **Check**: invoke the function once and confirm that the message and its thread reply arrive:
   ```bash
   aws lambda invoke --function-name bb-management-cost-report /dev/stdout
   ```

## Usage

### Configuration

Every setting is a variable in `variables.tf`, passed to the Lambda as an environment variable.

| Variable | Default | What it does |
|---|---|---|
| `report_run_schedule` | `cron(0 12 * * ? *)` | When the report runs (UTC). |
| `report_slack_channel_id` | the report's channel | Where the bot posts. Empty: the webhook posts, without a thread. |
| `report_items_length` | `20` | How many top services the table shows. |
| `report_mover_min_usd` | `0.5` | Also list any service that moved by this much, even outside the top. |
| `report_group_by` | `SERVICE` | The table's grouping (a Cost Explorer dimension). |
| `report_budget_name` | the 100% budget of `management/global/cost-mgmt` | The AWS Budget shown under the month. Empty: none. |
| `report_alert_min_usd`, `report_alert_min_pct` | `1`, `30` | The alert thresholds; a move has to pass both. |
| `report_alert_mention` | empty | Slack mention added to the alerts, e.g. `<!here>`. |
| `report_drilldown_max` | `3` | Break down the largest N alerts by account and usage type. `0`: off. |
| `report_anomaly_days` | `14` | Show open anomalies that ended in the last N days. `0`: off. |
| `report_show_accounts` | `true` | Add the cost by account to the thread. Needs the bot. |
| `report_daily_mode` | `full` | `compact`: on quiet days, a one-line message instead of the full report. The full report still goes out on alert days, on `report_full_report_weekday` (default Monday), and on an invocation with `{"mode": "full"}`. |
| `report_help_url` | this section of the README | The "How to read this report" link in the message. Empty: the method is spelled out in the footer instead. |

### Testing and previewing

`src/` is the whole Lambda package, so the tests live in `tests/` and are never deployed. From the repository root:

- `make cost-report-test`: offline tests against the synthetic Cost Explorer responses in `tests/fixtures/`. Any test that tries to reach AWS fails.
- `make cost-report-preview`: builds today's report from live data with the management profile and prints it instead of posting it ($0.03–0.04 per run). It checks every message with Slack's `blocks.validate` and prints Block Kit Builder links.
- `make cost-report-preview SLACK_DM=<your Slack member ID>`: also posts the report, thread included, to your direct messages with the bot. It shows exactly what the channel would get, so this is the quickest way to iterate on the layout. You can find your member ID in your Slack profile → ⋮ → *Copy member ID*.

### Operations

- **Run it now**: `aws lambda invoke --function-name bb-management-cost-report --payload '{"mode": "full"}' --cli-binary-format raw-in-base64-out /dev/stdout`.
- **Logs**: CloudWatch log group `/aws/lambda/bb-management-cost-report`, kept for 7 days. Each run logs `mode=… alerts=… anomalies=…`, and a line for every optional part it had to leave out.
- **The report did not arrive**: the `bb-management-cost-report-errors` alarm notifies `sns-topic-costs`. Check the logs for the error.
- **Rotate the bot token**: reinstall the app in Slack, then put the new token in the secret as in [Installation](#installation). There is nothing to redeploy.
