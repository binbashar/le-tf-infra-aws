# Monthly cost email report: shape decision (#1297)

Status: **draft for review**. The bug fixes (#1297, section 1) ship separately in #1298
(`shared/us-east-1/tools-costs-email-notifications`); this document decides what the
report becomes so it can be offered as a low-maintenance client add-on.

Out of scope by decision: `management/global/cost-report` (the daily Slack report) is
**not** modified or extended. It serves a different purpose.

## Requirements

| # | Requirement | Source |
|---|---|---|
| R1 | One install, one `apply`, in the client's management (payer) account; no per-account roles | #1297 §2 |
| R2 | Client mailboxes in To, binbash in **CC** (agreed, visible), stopping automatically at contract end | #1297 §3 |
| R3 | Little or no per-client SES work | #1297 §3 |
| R4 | Totals reconcile with the invoice; sent after the month closes | #1297 §4, §5 |
| R5 | binbash learns when the report fails | #1297 §5 |
| R6 | Content worth more than the native AWS baseline: org summary, $ and % change, top movers, forecast, budget, credits, anomalies | #1297 §4 |

## Native baseline (what we must beat)

| Option | What it sends | Fit |
|---|---|---|
| **AWS Budgets reports** | Budget vs actual, per budget; US$0.01 per delivery | No per-service / per-account month-over-month breakdown unless a budget exists per slice |
| **Billing and Cost Management Dashboards, scheduled email** (GA April 2026) | A **link** to a password-protected PDF snapshot of a custom dashboard; daily / weekly / monthly at a UTC time; no extra charge announced in us-east-1 | Closest native competitor. Recipients must verify through AWS User Notifications (a distribution list works for non-AWS users). Link expires after 15 days, password is in the same email, no inline content, no CC semantics, no contract end date. API: `bcm-dashboards:CreateScheduledReport`; Terraform support unconfirmed |

Takeaway: the dashboard email covers "a picture of the bill" for free. A custom report
earns its maintenance only by **R2 + R6**: an inline, readable email with the binbash CC
and contract end built in, a narrative summary (what moved and why it matters), and the
extra signals (forecast, budget, credits, anomalies, untagged share). If we cannot deliver
those, the recommendation for clients is the native dashboard email plus a runbook.

Open check before committing: whether a dashboard created in the management account
covers all linked accounts (the docs do not say), and whether it can be created with
OpenTofu.

## Options

### A. Keep the layer in `shared`, fix in place (status quo)
- Per-account `LambdaCostsExplorerAccess` roles stay (8 `base-identities` layers), plus
  the Organizations discovery path and per-account partial failures.
- Coupled to Leverage remote state (`notifications`, `security-keys`) and `var.accounts`.
- Fails R1. Fine as the reference-architecture's own report until B lands; not a client add-on.

### B. New layer in the management account, single payer query
- e.g. `management/global/cost-email-report`. One `GetCostAndUsage` grouped by
  `LINKED_ACCOUNT` + `SERVICE` per month returns the whole organization: 2 requests for the
  table instead of ~3 per account, no role assumption, no Organizations auto-discovery
  (account names via `organizations:ListAccounts` in the same account, no role).
- Starts from the existing `script.py` (now tested), restructured around one query.
- Meets R1 in our own organization; still a layer, so a client copies a directory.

### C. Versioned module consumed by a thin layer
- e.g. `binbashar/terraform-aws-cost-email-report`, with ~6 inputs:
  `client_name`, `client_recipients`, `binbash_recipients`, `binbash_reporting_until`,
  `sender` (+ `ses_identity_arn`), `schedule_expression`.
- Our `management/global/...` layer becomes the first consumer; clients get the same
  module pinned by tag, and Renovate bumps it.
- Meets R1 fully. Cost: one more repo to release.

### D. Native only
- Budgets / dashboard email per client, no code. Fails R2 (no automatic stop, no CC) and
  most of R6.

## Recommendation

**B, built so that it extracts into C without rewriting**: develop it as a local module
inside the new management layer (`modules/` or a `src/` + `module.tf` boundary with only
the C inputs), prove it on our organization for one or two monthly cycles, then move it
to its own repo and tag `v1.0.0`. Then retire A and the `LambdaCostsExplorerAccess`
roles in a separate PR once nothing assumes them.

## Sub-decisions

### SES: who owns the sending identity (R3)

Current state (checked 2026-11-02): SES in the `shared` account is in the **sandbox**
(`ProductionAccessEnabled: false`, 200 messages / 24 h) and holds only six verified
`binbash.com.ar` **email** identities. The layer manages one of them, a personal sender
address (`ses.tf`). There is no `binbash.com.ar` domain identity anywhere in this repo; the
only domain identity is `binbash.co`, in `apps-prd/us-east-1/app-ai-lab`. Today every
recipient must therefore be a verified address.

| Option | Per-client work | Notes |
|---|---|---|
| **1. binbash-owned identity, cross-account sending authorization** (recommended) | One statement in binbash's identity policy allowing the client's management account; none in the client | binbash verifies `binbash.com.ar` (or a subdomain such as `reports.binbash.com.ar`) with DKIM **once**, in one account with SES production access. The client Lambda calls `SendEmail` with `SourceArn` = binbash's identity ARN. No sandbox, no per-client DNS. Bounces/complaints count against binbash's reputation; restrict the policy with `aws:SourceAccount`. Revoking at contract end also stops the client's copy, so keep the date input too |
| 2. Client-owned domain identity | Verify the client domain + DKIM, request SES production access (1–2 days) | Clean ownership; the most friction, and it is the step that makes installs slow |
| 3. Email identities in the sandbox | Every recipient clicks a verification link | Today's model; not acceptable for client mailboxes |

### Recipients and contract end (R2)
- `client_recipients` → `To`, `binbash_recipients` → `Cc`, one `SendEmail` per month.
- `binbash_reporting_until = "YYYY-MM-DD"` evaluated by the Lambda at send time; after
  it, binbash is dropped from `Cc` and the report keeps going to the client. A date in the
  past is a plan-time validation warning, not an error.
- `client_name` in the subject and header (`[<client>] AWS cost report — October 2026`)
  so one binbash mailbox can filter many clients.

### Schedule and reliability (R4, R5)
- Run on the **5th at 12:00 UTC** (`cron(0 12 5 * ? *)`); month-end support, tax and
  Savings Plans charges land after the 1st. Label the report "preliminary" if forced earlier.
- Failure alarm: also notify binbash. Simplest is an SNS email subscription for
  `binbash_recipients` on a topic the module creates (one confirmation click per client).
  Alternative: a "report not received by the 6th" check on binbash's side, which also
  catches a deleted stack.
- Retries: set `maximum_retry_attempts = 0` on the async invoke config, or record the
  sent month (e.g. an SSM parameter) and skip a second send. The send is the last step,
  so the duplicate risk is low today; it grows once more steps follow it.

### Content (R6)
Summary first: organization total, change in $ and %, top 3 services by increase, top 3
accounts by spend; % only shown above a $ threshold (no "100%" for $0 → $0.03). Then
credits, tax and support as separate lines so the total matches the invoice, then
forecast, budget status, remaining credits, open anomalies, Savings Plans coverage and
untagged share. Each extra signal is 1 Cost Explorer request (US$0.01), so a full report
stays well under US$0.20 per month.

Tests and a local HTML preview (`tests/preview.py` rendering a fixture to a file) come
with the module, so a prospect can see a sample before installing.

## Decisions needed

1. Approve **B → C** (or pick another option).
2. SES model: **binbash-owned identity with cross-account authorization**, and which
   domain (`binbash.com.ar`, a subdomain, or `binbash.co`) and which account hosts it.
3. Which binbash mailbox goes in CC.
4. Failure notification: SNS email subscription vs a check on binbash's side.

## References
- [Scheduling email delivery of dashboard reports](https://docs.aws.amazon.com/cost-management/latest/userguide/schedule-dashboard-reports.html)
- [Automate AWS cost reporting with scheduled dashboard email delivery](https://aws.amazon.com/blogs/aws-cloud-financial-management/automate-aws-cost-reporting-with-scheduled-dashboard-email-delivery)
- [SES: sending emails for the identity owner (sending authorization)](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/sending-authorization-delegate-sender-tasks-email.html)
