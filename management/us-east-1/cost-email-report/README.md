# Monthly cost email report

Monthly AWS cost report by email, sent from the management (payer) account (#1297).

> **Status: SES only.** This layer currently sets up the sending domain. The report
> itself (Lambda, schedule, recipients) comes next. Until then the old report keeps
> running from `shared/us-east-1/tools-costs-email-notifications`.

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
| SES | A **domain** identity with Easy DKIM in the same account, plus SES production access | Email identities in the sandbox make every recipient verify their address |
| Recipients | The installation's mailboxes in To; the binbash copy in **CC** (visible, agreed in the contract) to `sales@binbash.com.ar`, dropped automatically after a `binbash_reporting_until` date | binbash keeps visibility for the contract's length without anyone having to remember to remove it. Empty in binbash's own installation |
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

**Roadmap:** SES (this layer, now) → the report Lambda, run alongside the old one for one
or two monthly cycles → retire `shared/us-east-1/tools-costs-email-notifications` and the
`LambdaCostsExplorerAccess` roles → a client installation runbook.

Out of scope: `management/global/cost-report`, the daily Slack report.

## What it creates

| Resource | Purpose |
|---|---|
| `aws_sesv2_email_identity.domain` | `var.ses_domain` as an SES **domain** identity with Easy DKIM (2048-bit). Any address under the domain can send |
| `aws_route53_record.dkim` (×3) | The DKIM `CNAME` records, in the domain's public zone through the `aws.dns` provider (the `shared` account for `binbash.com.ar`) |

SES signs with `d=<ses_domain>`, so DMARC passes on DKIM alignment. The envelope
`MAIL FROM` stays on `amazonses.com`, so the domain's SPF record needs no change.

## Install

The `aws` commands below must run against the **management account** in **us-east-1**;
`put-account-details` in the wrong account or region requests production access there
instead. With Leverage's credentials (adjust the profile in a client installation):

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
3. **Request SES production access, once per account and region.** The AWS provider has
   no resource for it. Until it is granted, SES is in the sandbox: 200 messages a day,
   and every recipient must be a verified identity.
   ```bash
   aws sesv2 put-account-details \
     --production-access-enabled \
     --mail-type TRANSACTIONAL \
     --website-url https://<company website> \
     --contact-language EN \
     --use-case-description "One internal monthly AWS cost report per month, sent from <ses_domain> to a handful of the organization's own mailboxes. No marketing, no lists. Bounces and complaints are handled by the account owner."
   ```
   AWS answers through a support case, usually within a day. Check with
   `aws sesv2 get-account --query '{prod:ProductionAccessEnabled,review:Details.ReviewDetails}'`.

## In a client installation

- Set `ses_domain` to the client's domain.
- Point the `aws.dns` provider and `data.terraform_remote_state.dns` at the account that
  holds the client's public zone. If their DNS is not in Route53, set
  `manage_dns_records = false` and hand them the `dkim_records` output.
- Request production access in the client's management account (step 3 above).
