# Monthly cost email report: shape decision (#1297)

Status: **decided** (2026-11-02). The bug fixes to the current layer
(`shared/us-east-1/tools-costs-email-notifications`, #1297 section 1) shipped and were
applied in #1298. This document records what the report becomes next.

## Purpose

The report has two uses, and the design has to serve both:

1. **binbash's own monthly cost email** for this organization.
2. **Reference code for client implementations.** When we implement it for a client, we
   copy this layer into the client's repository and adapt it: the client's own domain,
   SES identity and mailboxes. If the client agrees, a dedicated binbash mailbox receives
   a copy of the report in CC, so we keep visibility on the client's spend for the length
   of the contract.

Out of scope by decision: `management/global/cost-report` (the daily Slack report) is
**not** modified or extended. It serves a different purpose.

## Requirements

| # | Requirement | Source |
|---|---|---|
| R1 | Runs in the management (payer) account with one `apply`; no per-account roles | #1297 §2 |
| R2 | Easy to copy into a client repo: everything installation-specific is an input, no binbash-only dependencies | Purpose |
| R3 | Installation's own mailboxes in To; optional binbash copy in **CC** (agreed, visible), stopping automatically at contract end | #1297 §3 |
| R4 | SES set up once per installation, with the installation's own domain, out of the sandbox | #1297 §3 |
| R5 | Totals reconcile with the invoice; sent after the month closes | #1297 §4, §5 |
| R6 | Content worth more than the native AWS baseline: org summary, $ and % change, top movers, forecast, budget, credits, anomalies | #1297 §4 |

## Native baseline (what we must beat)

| Option | What it sends | Fit |
|---|---|---|
| **AWS Budgets reports** | Budget vs actual, per budget; US$0.01 per delivery | No per-service / per-account month-over-month breakdown unless a budget exists per slice |
| **Billing and Cost Management Dashboards, scheduled email** (GA April 2026) | A **link** to a password-protected PDF snapshot of a custom dashboard; daily / weekly / monthly at a UTC time; no extra charge announced in us-east-1 | Closest native competitor. Recipients must verify through AWS User Notifications (a distribution list works for non-AWS users). Link expires after 15 days, password is in the same email, no inline content, no CC semantics, no contract end date. API: `bcm-dashboards:CreateScheduledReport`; Terraform support unconfirmed |

Takeaway: the dashboard email covers "a picture of the bill" for free. The custom report
earns its maintenance through **R3 + R6**: an inline, readable email with the optional
binbash CC and contract end built in, a summary of what moved, and the extra signals
(forecast, budget, credits, anomalies, untagged share).

## Options considered

| Option | Verdict |
|---|---|
| **A.** Keep the layer in `shared`, fixed in place | Rejected as the target. Needs `LambdaCostsExplorerAccess` in every account (8 `base-identities` layers), Organizations discovery and per-account partial failures; coupled to the `notifications` / `security-keys` remote state. Stays in service until B replaces it |
| **B.** New self-contained layer in the management account, single payer query | **Chosen.** The layer itself is the reference code |
| **C.** Versioned module (e.g. `binbashar/terraform-aws-cost-email-report`) consumed by thin layers | Rejected. Client implementations copy and adapt the layer; a module repo to release adds cost without matching that workflow. Trade-off accepted: copies diverge, and later fixes are ported to clients by hand |
| **D.** Native only (Budgets reports / dashboard email) | Rejected. No CC with a contract end date and most of R6 missing |

## Decision

### Shape: one layer in management (B)
- e.g. `management/global/cost-email-report`. One `GetCostAndUsage` per month grouped by
  `LINKED_ACCOUNT` + `SERVICE` returns the whole organization: no role assumption, no
  per-account queries. Account names come from `organizations:ListAccounts` in the same
  account.
- Built from the current `script.py` and its tests, restructured around the single query.
- **Copy-friendly (R2):** every installation-specific value is a variable with no
  binbash default; no remote state other than what any Leverage layer has; the alarm
  topic is an input. Copying it to a client means copying the directory and filling in
  its `.tfvars`.
- Once it has run for one or two monthly cycles, retire `shared/us-east-1/tools-costs-email-notifications`
  and then the `LambdaCostsExplorerAccess` roles, each in its own PR.

### SES: a domain identity in the management account (R4)
- Current state (checked 2026-11-02): SES in the `shared` account is in the **sandbox**
  (`ProductionAccessEnabled: false`, 200 messages / 24 h) and holds only six verified
  `binbash.com.ar` **email** identities. There is no `binbash.com.ar` domain identity in
  this repo; the only domain identity is `binbash.co`, in `apps-prd/us-east-1/app-ai-lab`.
- **Our installation:** verify `binbash.com.ar` as a domain identity with DKIM in the
  **management** account, the same account as the Lambda. The DKIM `CNAME` records go in
  the public zone in `shared` (`shared/global/base-dns/binbash.com.ar`) through an aliased
  provider. Request SES production access for the management account once.
- **Client installations:** the same pattern in the client's management account with the
  client's domain; where their DNS is not in Route53, the DKIM records are handed to them.
  This one-time step goes in the runbook.

### Recipients and contract end (R3)
- `recipients` → `To`; `binbash_recipients` → `Cc`; one `SendEmail` per month.
- The binbash copy goes to a **dedicated binbash mailbox** (to be created), used for every
  client so the reports can be filtered in one place. It is **empty in our own
  installation**.
- `binbash_reporting_until = "YYYY-MM-DD"`, evaluated by the Lambda at send time; after
  it, binbash is dropped from `Cc` and the report keeps going to the client. Pair it with
  the consent clause in the contract.
- An `organization_name` input in the subject and header
  (`[<organization>] AWS cost report — October 2026`), so the binbash mailbox can tell
  clients apart.

### Failures
- The error alarm publishes to the **installation's own SNS topic** only. binbash is not
  alerted about a client's failures. Accepted consequence: if a client's report stops
  arriving, the binbash copy simply stops too, and noticing that is manual.

### Schedule and reliability (R5)
- Run on the **5th at 12:00 UTC** (`cron(0 12 5 * ? *)`); month-end support, tax and
  Savings Plans charges land after the 1st.
- Set `maximum_retry_attempts = 0` on the async invoke config, or record the sent month
  (e.g. an SSM parameter) and skip a second send, so a retry cannot duplicate the email.

### Content (R6)
Summary first: organization total, change in $ and %, top 3 services by increase, top 3
accounts by spend; % only shown above a $ threshold (no "100%" for $0 → $0.03). Then
credits, tax and support as separate lines so the total matches the invoice, then
forecast, budget status, remaining credits, open anomalies, Savings Plans coverage and
untagged share. Each extra signal is one Cost Explorer request (US$0.01), so a full
report stays well under US$0.20 per month.

Tests and a local HTML preview (rendering a fixture to a file) come with the layer, so a
prospect can see a sample before installing. `tests/send_test_report.sh` (added in #1298)
keeps sending a real report to one inbox without deploying.

## Next steps
1. Create the dedicated binbash mailbox.
2. SES in management: domain identity + DKIM records in the `shared` zone, then the
   production access request.
3. Build `management/global/cost-email-report` (B), with the recipient model, schedule,
   reliability fixes and content above.
4. Run it alongside the current report for one or two cycles, then retire the `shared`
   layer and the `LambdaCostsExplorerAccess` roles.
5. Write the client installation runbook (copy, `.tfvars`, SES, consent clause).

## References
- [Scheduling email delivery of dashboard reports](https://docs.aws.amazon.com/cost-management/latest/userguide/schedule-dashboard-reports.html)
- [Automate AWS cost reporting with scheduled dashboard email delivery](https://aws.amazon.com/blogs/aws-cloud-financial-management/automate-aws-cost-reporting-with-scheduled-dashboard-email-delivery)
- [Amazon SES: verifying a domain identity with Easy DKIM](https://docs.aws.amazon.com/ses/latest/dg/creating-identities.html)
