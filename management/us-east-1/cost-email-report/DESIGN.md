# Monthly cost email report: design

Why the report is built the way it is (#1297). For what it creates and how to run it, see
the [README](README.md); to install it for a client, the [runbook](RUNBOOK.md).

## Two uses

This layer is binbash's own monthly cost email, and the **reference code** we copy into a
client's repository and adapt to their domain, SES and mailboxes. If the client agrees,
binbash receives a copy of the report.

## Decisions

| Topic | Decision | Why |
|---|---|---|
| Shape | One self-contained layer in the management account. No versioned module | Clients get a copy of this directory. Trade-off: copies diverge and later fixes are ported by hand |
| Data | One `GetCostAndUsage` grouped by `LINKED_ACCOUNT` + `SERVICE` from the payer | Covers the whole organization with no per-account `LambdaCostsExplorerAccess` roles |
| Inputs | Everything installation-specific is in `report.auto.tfvars`, except the account that holds the DNS zone (`shared`), written literally in `config.tf` | Copying it to a client means rewriting one file. The DNS profile stays literal because Leverage reads profiles from `config.tf` to refresh their credentials, and skips computed values |
| SES | A **domain** identity with Easy DKIM in the same account. Production access only when needed (see [SES sandbox](README.md#ses-sandbox-is-production-access-needed)) | In the sandbox, every address under a verified domain is a valid recipient, so the domain identity alone covers the installation's own mailboxes |
| Recipients | The installation's mailboxes in To; the binbash copy in **CC** (visible, agreed in the contract) to `finops@binbash.com.ar`, dropped automatically after a `binbash_reporting_until` date | binbash keeps visibility for the contract's length without anyone having to remember to remove it. Empty in binbash's own installation |
| Failures | The error alarm notifies the installation's own SNS topic only | binbash is not alerted about a client's failures; a missing copy is noticed by hand |
| Schedule | The 5th of the month, 12:00 UTC | Support, tax and Savings Plans charges land days after the 1st |
| Retries | No duplicate email on a Lambda retry (`maximum_retry_attempts = 0`) | EventBridge invokes asynchronously and Lambda retries on error |

## Content

A summary first: organization total, change in $ and %, top services by increase and top
accounts by spend, with % shown only above a $ threshold. Then credits, tax and support as
separate lines so the total matches the invoice, plus forecast, budget status, remaining
credits, open anomalies, Savings Plans coverage and untagged share. Each extra signal is
one Cost Explorer request (US$0.01).

## Native baseline

AWS Budgets reports email budget vs actual, but with no per-service or per-account
breakdown. The Billing and Cost Management Dashboards **scheduled email** (GA April 2026,
free in us-east-1) sends a link to a password-protected PDF that expires after 15 days,
with no inline content, no CC and no contract end. This report has to stay ahead of that:
an inline summary, the binbash copy, and the extra signals.

## History

SES identity (#1302) → the report Lambda (#1303) → the old
`shared/us-east-1/tools-costs-email-notifications` report and its per-account
`LambdaCostsExplorerAccess` roles retired (#1304) → the client installation runbook.

Out of scope: `management/global/cost-report`, the daily Slack report.
