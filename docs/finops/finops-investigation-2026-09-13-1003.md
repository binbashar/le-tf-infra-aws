# AWS FinOps Investigation Report
**Date:** 2026-09-13
**Period:** September 2026 month-to-date (Sep 1–12) vs August 2026 (full month)

> **How to read this report.** Items are flagged by urgency:
> 🔴 **act this week** · 🟡 **keep an eye on it over the next month** ·
> 🟢 **healthy, no action needed**. Dollar figures are monthly unless noted.
> A plain-English glossary of any technical terms is at the bottom.

---

## Bottom line

Your AWS infrastructure is currently costing you **nothing in cash** — promotional
credits are absorbing 100% of September's usage. That is good news with a catch: it
hides a real running cost of about **$266/month**, and the credit pool paying for it
**expires on 2027-03-31**. At the current rate of spending you will only use about
$1,900 of the $4,624 remaining, so roughly **$2,700 of credit is on track to be
thrown away** — and a similar amount, about **$3,083, already appears to have expired
unused in March 2026**.

The single most urgent operational issue is different: **99.3% of your AWS spend
cannot be attributed to any project or team**, so nobody can be held accountable for
it.

---

## Executive Summary

- **Act this week:** 2 items — almost no spend can be traced to a team or project (99.3% unattributable), and your $750 monthly spending alert is set up so it will trip every month for a reason nobody can act on.
- **Keep an eye on:** 3 items — ~$2,700 of expiring credit likely to be wasted by March 2027; the Cost Explorer reporting API costing ~$55/month (20% of all usage); AI model spend that stopped dead on 1 September and should be confirmed as intentional.
- **Biggest change since last month:** Amazon Bedrock (AI models) fell from **$269.55 to $0.00** (−100%), which was 45.9% of August's entire usage bill.
- **Unusual spikes:** none detected — but see the caveat: automatic spike detection was only switched on 2 days ago and cannot yet detect anything.
- **Cost visibility:** **No** — 99.3% of spend has no project label. Risk level: **HIGH**.
- **Where it's heading:** about **$891** this month against a **$750** budget (~19% over), but the overage is entirely a known $625 software subscription, not infrastructure. Underlying infrastructure is flat-to-declining.

---

## 🔴 Act this week  *(urgent)*

| # | What's happening | Service / Account | $ Impact | What to do (and who) |
|---|------------------|-------------------|----------|----------------------|
| 1 | **Almost none of your AWS bill can be traced back to a team or project.** AWS lets you attach labels ("cost-allocation tags") to every resource so the bill can be split by who caused it. Of September's $109.13 of usage, **$108.37 (99.3%)** carries no `Project` label. The labels *are* being applied to resources by the infrastructure code — `Environment` and `Layer` were both used as recently as 2026-09-01 — but they were never **switched on** for billing, which is a separate one-time step. | All accounts | N/A (governance) | Ask whoever administers the AWS management account to activate these exact cost-allocation tag keys in Billing → Cost Allocation Tags: **`Environment`** and **`Layer`** (both currently *Inactive* despite being in active use), and to create and activate a **`CostCenter`** key, which does not exist at all. `Project`, `Owner`, `Component` and `Terraform` are already active and need no action. Data only accrues from activation onward, so every week of delay is a week that can never be split by team. |
| 2 | **Your $750/month spending alert is guaranteed to fire, for a reason nobody can act on.** The alert counts a fixed **$625/month Drata software subscription** (bought through the AWS Marketplace) in the same pot as infrastructure. Infrastructure alone is about $266/month — comfortably inside budget — but $266 + $625 = ~$891, so the alert trips every month regardless of how well the infrastructure is run. An alarm that always fires gets ignored, and then a real problem slips past it. | Management account — budgets `budget-MONTHLY-management-75-percent` and `budget-MONTHLY-management-100-percent` | ~$141–168 over budget (19–22%) | Ask your platform/DevOps team to either (a) add a filter to both budgets that excludes AWS Marketplace charges, so the $750 tracks infrastructure only, or (b) raise the limit to a figure that deliberately includes the $625 subscription (e.g. $1,400). Option (a) is preferable — it keeps the alert meaningful. |

---

## 🟡 Keep an eye on  *(monitor over the next month)*

| # | What's happening | Service / Account | $ Impact | What to do (and who) |
|---|------------------|-------------------|----------|----------------------|
| 1 | **About $2,700 of free AWS credit is on track to be thrown away.** A $5,000 credit ("APN Fee Reconciliation 3/10/26") has **$4,623.66 left** and **expires 2027-03-31**. You are currently consuming credit at about **$9.68/day**, which over the 199 days remaining uses only ~$1,926 of it. Unused credit is simply lost on the expiry date. This is not hypothetical: an earlier $5,000 credit ("APN Fee Reconciliation 3/17/25") shows **$3,082.76 still unspent against an end date of 2026-03-31 that has already passed**, plus ~$592 across five smaller expired promotions. | Management account | ~$2,700 at risk; ~$3,083 apparently already lost | Whoever owns the AWS partner relationship should confirm with your AWS account team whether the March-2026 balance was genuinely forfeited, and ask what the credit may be spent on. Then decide deliberately whether to pull planned work forward into the credit window rather than letting it lapse. |
| 2 | **The reporting API you use to analyse costs is now your single biggest usage line.** AWS charges **$0.01 per Cost Explorer request**. That came to **$21.85 in 12 days (~$55/month)** — **20% of all September usage** — and $55.92 in August. That implies roughly **180 requests per day**, which is far more than a human checking dashboards; something automated is polling it. | AWS Cost Explorer — management account | ~$55/month | Ask your platform/DevOps team to find what is calling Cost Explorer on a schedule (a dashboard, a cost tool, or a CI job) and cache or reduce its polling. For reference, generating *this* report cost about $0.12. |
| 3 | **AI model spending stopped completely on 1 September and nobody has confirmed that was intended.** Amazon Bedrock (AWS's hosted AI models) billed **$269.55 in August** — 45.9% of the whole usage bill, mostly Claude Opus 5 at $206.44 — and **exactly $0.00 so far in September**. Two other services went to zero the same way: Amazon DynamoDB (a database) $20.31 → $0.00, and Amazon SageMaker (machine-learning platform) $10.45 → $0.00. This is verified as real, not missing data: every single day of September has complete billing records. | Bedrock / DynamoDB / SageMaker | −$300/month (a saving) | Ask the data-science and platform teams to confirm this was a deliberate migration off Bedrock rather than a workload that silently broke. A cost drop is only good news if someone meant to cause it. |

---

## What changed most since last month

August was a full 31-day month and September so far is 12 days, so the table compares
**average cost per day** — otherwise every line would look like it fell simply because
less time has passed.

| Service (what it is) | Aug total | Aug $/day | Sep $/day | Change ($/day) | Change (%) |
|----------------------|----------:|----------:|----------:|---------------:|-----------:|
| Claude Opus 5 — Amazon Bedrock (hosted AI models) | $206.44 | $6.66 | $0.00 | −$6.66 | −100% |
| Claude Sonnet 5 — Amazon Bedrock | $58.89 | $1.90 | $0.00 | −$1.90 | −100% |
| Amazon DynamoDB (managed NoSQL database) | $20.31 | $0.655 | $0.00 | −$0.655 | −100% |
| Amazon SageMaker (machine-learning platform) | $10.45 | $0.337 | $0.00 | −$0.337 | −100% |
| Amazon EKS (managed Kubernetes — runs containerised apps) | $6.05 | $0.195 | $0.036 | −$0.159 | −81% |
| Claude Haiku 4.5 — Amazon Bedrock | $3.37 | $0.109 | $0.00 | −$0.109 | −100% |
| AmazonCloudWatch (monitoring and logs) | $6.04 | $0.195 | $0.095 | −$0.100 | −51% |
| AWS Cost Explorer (the cost-reporting API itself) | $55.92 | $1.804 | $1.821 | +$0.017 | +0.9% |
| Amazon S3 (file/object storage) | $54.84 | $1.769 | $1.786 | +$0.017 | +1.0% |
| AWS Key Management Service (encryption-key management) | $44.68 | $1.441 | $1.489 | +$0.048 | +3.3% |

**There were no meaningful cost increases this month** — every material movement is a
decrease. The story is entirely the disappearance of Amazon Bedrock AI-model usage,
which alone accounts for **$269.55** of August's $586.79 usage bill.

All of these are **usage** changes, not **rate** changes: the same resources are not
being billed at a higher price: workloads simply stopped running. No extended-support
surcharges or expiring commitments were found in the usage data. The only line that
*looks* like an increase is Amazon Route 53 (DNS), whose per-day figure doubled purely
because its fixed monthly fee lands on the 1st of the month and is spread over 12 days
so far rather than 31.

---

## Unusual spikes

**None detected — but this result carries an important caveat and should not be read
as "nothing happened."**

Automatic spike detection (AWS Cost Anomaly Detection) returned zero anomalies for the
last 90 days. That is because the detector itself, `bb-management-service-monitor`, was
only created on **2026-09-11 — two days ago**. AWS needs roughly **10 days** of
observation to learn a normal pattern before it can flag an abnormal one. It has no
history to compare against yet.

**Expect this section to stay empty until about 2026-09-21.** The next run after that
date is the first one whose "no anomalies" result is genuinely meaningful.

Note also that the single largest cost event in this period — Bedrock dropping to zero —
is a *decrease*, and anomaly detection is tuned to catch increases.

---

## Cost visibility — can we tell who's spending what?

AWS can label each cost with the team, project, or environment responsible (these
labels are called "cost-allocation tags"). Without them the bill is one large
undifferentiated number and no one team can be asked to own their share.

- Share of the bill that **can't** be attributed to a team/project: **99.3%**
  (**$108.37** of $109.13 in September usage)
- Where it's worst: effectively everywhere. Only **$0.76** of spend carries a `Project`
  label, nearly all of it under the value `bb`.
- Risk level: **HIGH** (anything above 30% unattributable is high)

The important nuance: **this is not a case of engineers forgetting to label things.**
The infrastructure code applies `Environment`, `Layer` and `Terraform` labels to
resources as standard, and AWS confirms `Environment` and `Layer` were both seen on
billed resources as recently as 2026-09-01. They are simply not *activated* for billing
— a separate, one-time administrative switch in the management account. Flipping it is
a small task with a disproportionate payoff.

For reference, spend does break down cleanly **by account** today, which is a partial
substitute (September month-to-date, usage only):

| Account | Sep 1–12 | Share |
|---|---:|---:|
| binbash-apps-devstg | $37.85 | 34.7% |
| binbash-data-science | $27.22 | 24.9% |
| binbash-shared | $13.34 | 12.2% |
| binbash-management | $11.12 | 10.2% |
| binbash-apps-prd | $10.89 | 10.0% |
| binbash-network | $5.04 | 4.6% |
| binbash-security | $3.26 | 3.0% |
| binbash-workshop-genai-1 / -2 / -3 | $0.40 | 0.4% |

---

## Where spending is heading

- **This month's projected total: about $891** *(budget: $750 — roughly **$141 over, or
  19%**)*. AWS's own two forecasts disagree with each other and both are incomplete, so
  this figure is built from actuals instead:
  - Cost Explorer forecasts **$176.99** (range $152.73–$201.24).
  - The Budgets service forecasts **$293.15**.
  - Neither includes the **$625 Drata subscription**, which bills mid-month and had not
    yet posted when this report ran. It is an expected, contracted charge listed in
    `docs/finops/known-charges.md` — not a surprise.
  - Measured directly: September is running at a very steady **$8.70/day**, giving
    ~$266 of usage for the month. **$266 + $625 = ~$891.**
- **Yes, AWS will report the budget as exceeded** — but read it correctly. Infrastructure
  at ~$266 is only 35% of the $750 limit. The breach is caused entirely by the fixed
  software subscription sharing the same budget line (see 🔴 item 2).
- **What you will actually be invoiced is lower still.** Promotional credits are
  currently absorbing 100% of usage, so the cash cost of infrastructure is about **$0**.
  The realistic invoice is roughly the **$625** subscription, which credits do not cover.
- **Next 3 months:** flat to declining, provided the Bedrock workloads stay off. Treat
  this as a rough direction rather than a precise number — a single month of data since
  the Bedrock drop is a thin basis for a trend.
- **The cliff to plan for:** when the credit pool expires on **2027-03-31**, infrastructure
  cost moves from ~$0 to its true ~$266/month in cash, all at once.

---

## Suggested Follow-up

Run **`/aws-finops-optimize`** for the savings side of the picture. It looks for things
this report deliberately does not: oversized or idle resources, Savings Plans and
Reserved Instance coverage, and per-service waste (unattached disks, idle load
balancers, old snapshots). A first pass has already shown **$13.75/month** of identified
savings waiting in AWS Cost Optimization Hub.

---

## Glossary

- **Month-to-date (MTD)** — from the 1st of the current month until today.
- **Month-over-month (MoM)** — this month compared with the previous one.
- **Forecast** — AWS's projection of where the month's total will land.
- **Budget** — a spending limit you set that triggers an alert; it does not block spending.
- **Cost-allocation tag** — a label (e.g. `Environment=prd`) attached to a resource so the bill can be split by team, project, or environment. Must be explicitly *activated* before it affects billing reports.
- **Credit / promotional credit** — free AWS money applied automatically against your bill. It expires on a fixed date, and any unused balance is lost.
- **Usage vs. rate change** — "usage" means you ran more or fewer things; "rate" means the same things started costing more per unit. They need completely different fixes.
- **AWS Marketplace** — a store for third-party software billed through your AWS invoice. Drata is bought this way.
- **Amazon Bedrock** — AWS's service for running hosted AI models (Claude, etc.).
- **Amazon EKS** — managed Kubernetes; runs containerised applications.
- **Amazon RDS** — managed relational databases.
- **Amazon DynamoDB** — managed NoSQL database.
- **Amazon SageMaker** — machine-learning build/train/deploy platform.
- **Amazon S3** — file and object storage.
- **Amazon Route 53** — DNS (turns domain names into addresses).
- **AWS Key Management Service (KMS)** — manages encryption keys.
- **AWS Cost Explorer** — AWS's cost-reporting service; its API charges $0.01 per request.
- **AWS Security Hub / Amazon GuardDuty** — security monitoring services.
- **Amazon QuickSight** — business-intelligence dashboards.
- **Amazon VPC** — the private network your AWS resources run inside.

---

## Investigation Notes

*This section is the technical audit trail.*

**Cost basis.** All figures are `UnblendedCost`. Because credits currently offset ~100%
of usage, an unfiltered query returns ≈ $0 for every service and is actively misleading
— the first query of this run returned a total of `-0.0000167339` for Sep 1–12. All
service-level and account-level figures in this report are therefore filtered to
`RECORD_TYPE = Usage`, i.e. **gross usage before credits**. Charge-type split:

| Record type | Aug 2026 (final) | Sep 1–12 (estimated) |
|---|---:|---:|
| Usage | $586.79 | $109.13 |
| Other (AWS Marketplace — Drata) | $625.00 | $0.00 (not yet posted) |
| FlatRateSubscription | — | $7.04 |
| Credit | −$317.24 | −$116.16 |
| Tax | $0.00 | $0.00 |
| **Net total** | **$894.55** | **$0.003** |

- **Phase 0 allow-list honoured.** `docs/finops/known-charges.md` was read and applied.
  The $625 line was confirmed via a `RECORD_TYPE = Other` query to be
  `Drata Security & Compliance Automation Platform`, matching the `Drata` row exactly.
  It is therefore **counted everywhere but never raised as a finding or a mover**. It is
  consistent with its own history ($625.00 in August, same fixed amount), so the
  "came in higher than usual" escape hatch was not triggered. The `Partner Network`
  row did not match anything this period (it is an annual March charge).
  `accepted-exceptions.md` is seeded empty, as intended for a first run.
- **September data completeness verified.** Because Bedrock, DynamoDB and SageMaker all
  reported exactly $0.00, a daily series was pulled to rule out lagging data. All 12 days
  returned records, flat at $8.02–$9.27/day (Sep 1 higher at $13.26 owing to monthly
  upfront fees). The zeros are real.
- **Two AWS forecasts disagree** — Cost Explorer $176.99, Budgets $293.15, against a
  measured run-rate of ~$266. The two APIs use different models and neither anticipates
  the mid-month Marketplace charge. The report uses the actuals-derived figure and shows
  all three rather than silently picking one.
- **Budget cost basis inferred, not confirmed.** Budget `actual_spend` of $116.83 tracks
  gross usage ($116.17) rather than the net $0.003, so the budgets appear to exclude
  credits. This was inferred from the numbers; the budgets' `cost_filters` were not
  returned by the `budgets` MCP tool and were not independently verified.
- **Anomaly detection has no history.** `cost-anomaly` returned `[]` for 2026-06-15 →
  2026-09-13. Monitor `bb-management-service-monitor` was created 2026-09-11; AWS needs
  ~10 days to build a baseline. Not a data gap — a readiness gap. Meaningful from
  ~2026-09-21.
- **Credit expiry needs human confirmation.** Five credits show a non-zero
  `remainingAmount` against an `endDate` already in the past and a null `exhaustDate` —
  most materially $3,082.76 on "APN Fee Reconciliation 3/17/25" (ended 2026-03-31). The
  API does not state outright that the balance was forfeited; that reading is inferred
  from `endDate` semantics and should be confirmed with the AWS account team before being
  treated as a loss.
- **Tag-coverage method.** `Environment` is *Inactive* as a cost-allocation tag and
  therefore cannot be grouped on in Cost Explorer. Coverage was measured against
  `Project`, which is Active. Active keys: `Component`, `Owner`, `Project`, `Terraform`.
  Notable Inactive keys that are in live use: `Environment`, `Layer`, `Team`, `Service`,
  `Client`. `CostCenter` does not exist.
- **Account IDs deliberately omitted.** This repository is public; accounts are referred
  to by name only, per the rules in `CLAUDE.md`.
- **Cost of this run: 12 billed Cost Explorer API requests ≈ $0.12.** Cost Optimization Hub,
  Compute Optimizer, Budgets, `ListCostAllocationTags` and `get_credits` are separate APIs and
  are not billed. Both reports together: **17 requests ≈ $0.17**.
- **MCP-only data path honoured** for all cost data. No AWS CLI fallback was used for any
  figure in this report. (The AWS CLI appears in this session's history only for the
  credential preflight, which is what the `leverage-aws-creds-check` skill is specified
  to do.)
- **Environment caveat worth recording.** The MCP server could not resolve credentials at
  the start of this session because `AWS_PROFILE` is not set in the launching shell and
  the plugin's `.mcp.json` passes only `FASTMCP_LOG_LEVEL` and `AWS_REGION`. It was
  unblocked by pointing the `[default]` profile in `~/.aws/bb/config` at the management
  profile via `credential_process`. The durable fix belongs upstream in
  `bb-ai-marketplace`.
