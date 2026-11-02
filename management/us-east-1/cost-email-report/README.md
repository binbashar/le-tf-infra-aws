# Monthly cost email report

Monthly AWS cost report by email, sent from the management (payer) account (#1297).

> **Status: running alongside the old report.** Until it has run for one or two monthly
> cycles, `shared/us-east-1/tools-costs-email-notifications` keeps sending the old one.

## Design

**Two uses.** This layer is binbash's own monthly cost email, and the **reference code**
we copy into a client's repository and adapt to their domain, SES and mailboxes. If the
client agrees, binbash receives a copy of the report.

**Decisions:**

| Topic | Decision | Why |
|---|---|---|
| Shape | One self-contained layer in the management account. No versioned module | Clients get a copy of this directory. Trade-off: copies diverge and later fixes are ported by hand |
| Data | One `GetCostAndUsage` grouped by `LINKED_ACCOUNT` + `SERVICE` from the payer | Covers the whole organization with no per-account `LambdaCostsExplorerAccess` roles |
| Inputs | Everything installation-specific is a variable, with no binbash-only dependencies | Copying it to a client means filling in its variables |
| SES | A **domain** identity with Easy DKIM in the same account. Production access only when needed (see [SES sandbox](#ses-sandbox-is-production-access-needed)) | In the sandbox, every address under a verified domain is a valid recipient, so the domain identity alone covers the installation's own mailboxes |
| Recipients | The installation's mailboxes in To; the binbash copy in **CC** (visible, agreed in the contract) to `finops@binbash.com.ar`, dropped automatically after a `binbash_reporting_until` date | binbash keeps visibility for the contract's length without anyone having to remember to remove it. Empty in binbash's own installation |
| Failures | The error alarm notifies the installation's own SNS topic only | binbash is not alerted about a client's failures; a missing copy is noticed by hand |
| Schedule | The 5th of the month, 12:00 UTC | Support, tax and Savings Plans charges land days after the 1st |
| Retries | No duplicate email on a Lambda retry (`maximum_retry_attempts = 0` or a per-month send record) | EventBridge invokes asynchronously and Lambda retries on error |

**Content.** A summary first: organization total, change in $ and %, top services by
increase and top accounts by spend, with % shown only above a $ threshold. Then credits,
tax and support as separate lines so the total matches the invoice, plus forecast,
budget status, remaining credits, open anomalies, Savings Plans coverage and untagged
share. Each extra signal is one Cost Explorer request (US$0.01).

**Native baseline.** AWS Budgets reports email budget vs actual, but with no per-service
or per-account breakdown. The Billing and Cost Management Dashboards **scheduled email**
(GA April 2026, free in us-east-1) sends a link to a password-protected PDF that expires
after 15 days, with no inline content, no CC and no contract end. This report has to stay
ahead of that: an inline summary, the binbash copy, and the extra signals.

**Roadmap:** SES → the report Lambda (this layer, now), run alongside the old one for one
or two monthly cycles → retire `shared/us-east-1/tools-costs-email-notifications` and the
`LambdaCostsExplorerAccess` roles → a client installation runbook.

Out of scope: `management/global/cost-report`, the daily Slack report.

## What it creates

| Resource | Purpose |
|---|---|
| `aws_sesv2_email_identity.domain` | `var.ses_domain` as an SES **domain** identity with Easy DKIM (2048-bit). Any address under the domain can send |
| `aws_route53_record.dkim` (×3) | The DKIM `CNAME` records, in the domain's public zone through the `aws.dns` provider (the `shared` account for `binbash.com.ar`) |
| `module.cost_email_report` | The `<project>-<env>-cost-email-report` Lambda (`src/report.py`, python3.13), its role and its log group (90 days). Async retries are off, so a failure cannot send the email twice |
| `aws_cloudwatch_event_rule.schedule` | Runs it on `var.schedule_expression`: the 5th at 12:00 UTC |
| `module.errors_alarm` | Fires on any function error, which means no email that month; notifies the monitoring topic (Slack) |

SES signs with `d=<ses_domain>`, so DMARC passes on DKIM alignment. The envelope
`MAIL FROM` stays on `amazonses.com`, so the domain's SPF record needs no change.

The function's role can read costs (`ce:GetCostAndUsage`, `GetCostForecast`, `GetAnomalies`,
`GetSavingsPlansCoverage`), account names (`organizations:ListAccounts`), credit balances
(`billing:GetCredits`) and the configured budget, and send email from `var.sender` only.

## What the report reads

| Section | Source | Requests |
|---|---|---|
| Invoice lines (usage, Marketplace, tax, support, credits...) | Cost Explorer grouped by `RECORD_TYPE` | 1 |
| By account, by service per account | Cost Explorer grouped by `LINKED_ACCOUNT` + `SERVICE`, credits and refunds excluded | 1 per page |
| Current month forecast | Cost Explorer month-to-date + `GetCostForecast` | 2 |
| Cost anomalies | Cost Anomaly Detection, `anomaly_min_usd` and up | 1 |
| Savings Plans coverage | `GetSavingsPlansCoverage` | 1 |
| Untagged spend | Cost Explorer grouped by `untagged_tag_key` (off when empty) | 1 |
| Budget | AWS Budgets, `budget_name` (off when empty) | free |
| Credits remaining | Billing `GetCredits`: active, enabled credits only. **Not shown yet when deployed:** the boto3 bundled in the Lambda runtime (checked 2026-11-02) predates this API, so the read is skipped until AWS updates it; `tests/send_test_report.sh` shows it | free |

About 8 Cost Explorer requests, US$0.08 a month. The two Cost Explorer reads that build
the tables must succeed, or the function raises and nothing is sent. Every other read is
optional: when one fails, its line is left out of the summary and the report still goes.

## Install

The `aws` commands below must run against the **management account** in **us-east-1**.
With Leverage's credentials (adjust the profile in a client installation):

```bash
export AWS_CONFIG_FILE=~/.aws/bb/config AWS_SHARED_CREDENTIALS_FILE=~/.aws/bb/credentials
export AWS_PROFILE=bb-management-administrator AWS_REGION=us-east-1
aws sts get-caller-identity --query Account   # must be the management account
```

1. `leverage tofu apply` from this directory.
2. Wait for verification (usually minutes, up to 72 hours after the records resolve):
   ```bash
   aws sesv2 get-email-identity --email-identity <ses_domain> \
     --query '{verified:VerifiedForSendingStatus,dkim:DkimAttributes.Status}'
   ```

## Test and send by hand

```bash
# Unit tests (no AWS)
uv run --no-project --python 3.13 --with pytest --with boto3 python -m pytest tests/ -q

# The email for a sample organization, as an HTML file (no AWS)
python3 tests/preview.py /tmp/preview.html

# A real report, from this checkout, to ONE address under the verified domain (no deploy)
tests/send_test_report.sh you@<ses_domain> [YYYY-MM]

# The deployed function, to all its recipients (e.g. after fixing a failed month)
aws lambda invoke --function-name <project>-<env>-cost-email-report \
  --cli-binary-format raw-in-base64-out --payload '{"month": "2026-10"}' /dev/stdout
```
## SES sandbox: is production access needed?

Usually not. A new account's SES is in the **sandbox**: it sends only to verified
identities, up to 200 messages a day. A verified **domain** identity makes every address
under that domain a valid recipient, and one report a month is far below the quota.
Production access adds no deliverability: the email leaves through the same
infrastructure with the same DKIM signature. It only lifts the verified-recipient rule.

| Installation | Recipients | Production access |
|---|---|---|
| binbash | `@binbash.com.ar` mailboxes | **Not needed** |
| Client, no binbash copy | Mailboxes under the client's verified domain | **Not needed** |
| Client with the binbash copy | Also `finops@binbash.com.ar`, another domain | **Not needed** if `finops@binbash.com.ar` is verified as an email identity in the client's account (someone at binbash clicks the verification link). Needed otherwise |
| Client with outside recipients | e.g. an accountant on another domain | **Needed**, or verify each address |

In the sandbox, a recipient outside the verified identities makes the send fail; the
error alarm reports it.

To verify the binbash copy's address in a client's account:

```bash
aws sesv2 create-email-identity --email-identity finops@binbash.com.ar
```

To request production access instead, once per account and region (the AWS provider has
no resource for it; AWS answers through a support case, usually within a day):

```bash
aws sesv2 put-account-details \
  --production-access-enabled \
  --mail-type TRANSACTIONAL \
  --website-url https://<company website> \
  --contact-language EN \
  --use-case-description "One monthly AWS cost report, sent from <ses_domain> to a few mailboxes of the organization and of its cloud partner. No marketing, no lists. Bounces and complaints are handled by the account owner."
aws sesv2 get-account --query '{prod:ProductionAccessEnabled,review:Details.ReviewDetails}'
```

## In a client installation

- Set `ses_domain` to the client's domain, `sender` to an address under it,
  `organization_name` to the client's name and `recipients` to their mailboxes.
- If the contract includes the binbash copy: `binbash_recipients = ["finops@binbash.com.ar"]`
  and `binbash_reporting_until` = the contract's end date.
- Set `budget_name` to one of their budgets, or `""`; `untagged_tag_key` to an activated
  cost allocation tag, or `""`.
- Point the `aws.dns` provider and `data.terraform_remote_state.dns` at the account that
  holds the client's public zone. If their DNS is not in Route53, set
  `manage_dns_records = false` and hand them the `dkim_records` output.
- If the client agreed to the binbash copy, verify `finops@binbash.com.ar` in their account
  (see [SES sandbox](#ses-sandbox-is-production-access-needed)).
