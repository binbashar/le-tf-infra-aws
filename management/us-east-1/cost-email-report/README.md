# Monthly cost email report

Monthly AWS cost report by email, sent from the management (payer) account on the 5th:
the organization's total, its change, the top services and accounts, and the invoice
lines, forecast, budget, anomalies and Savings Plans coverage.

- Why it is built this way: [DESIGN.md](DESIGN.md)
- Installing it for a client: [RUNBOOK.md](RUNBOOK.md)
- This installation's values (domain, sender, recipients, budget): `report.auto.tfvars`

## What it creates

| Resource | Purpose |
|---|---|
| `aws_sesv2_email_identity.domain` | `var.ses_domain` as an SES **domain** identity with Easy DKIM (2048-bit). Any address under the domain can send |
| `aws_route53_record.dkim` (×3) | The DKIM `CNAME` records, in the domain's public zone in the `shared` account, through the `aws.dns` provider |
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

The `aws` commands below must run against the **management account** in **us-east-1**,
with Leverage's credentials (`<project>` is `PROJECT` in `build.env`, the profile is the one
in `management/config/backend.tfvars`):

```bash
export AWS_CONFIG_FILE=~/.aws/<project>/config AWS_SHARED_CREDENTIALS_FILE=~/.aws/<project>/credentials
export AWS_PROFILE=<project>-management-<role> AWS_REGION=us-east-1
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

See [RUNBOOK.md](RUNBOOK.md).
