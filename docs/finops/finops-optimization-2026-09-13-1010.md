# AWS FinOps Optimization Report
**Date:** 2026-09-13
**Period:** baseline **2026-08-01 → 2026-08-31** (last full calendar month) · **2026-09-01 → 2026-09-12** month-to-date shown as run-rate context only
**Cost basis:** `UnblendedCost`, usage charges only (`RECORD_TYPE = Usage`) — excludes AWS Marketplace / partner (APN), tax, Support, credits, refunds, and commitment fees
**Baseline usage spend:** $586.79 · **Materiality floor:** $5.87/month (1% of baseline)

---

## Executive Summary

Firmly quantified savings total **$75.32/month ($903.84/year)** — about **13% of the
$586.79 baseline usage bill** — spread across 10 findings, none individually large
because the estimate is deliberately conservative. A further **$103.35/month** sits in
two runaway request-volume patterns (S3 and the Cost Explorer API) whose fixable share
cannot be determined from billing data alone and which need one diagnostic session each.

The single cleanest win is an **Amazon API Gateway cache running 24/7 in us-west-2 at
$14.88/month** while the API it fronts serves 11,336 requests/month in a different
region — effectively 100% waste, in a region this architecture does not otherwise use.
Counting orphaned secrets alongside it, **us-west-2 carries ~$17.32/month with no
apparent workload behind it**.

The most important finding is not a saving but a **loss to avoid**: AWS Cost
Optimization Hub is recommending a **3-year DynamoDB reserved-capacity purchase**
(`$6.83/month` of claimed savings) based on a 30-day lookback that ended 2026-09-11.
That table served **23 requests in all of August** while 60 write and 60 read capacity
units sat provisioned, and its spend went to **$0.00 on 1 September**. Acting on that
recommendation would create roughly **$19.91/month of entirely new cost for three
years (~$717)**, not save anything.

Savings Plans posture: **0% coverage on $36.58/month of eligible spend — and buying one
is not recommended**, since the commitment minimums and 1–3 year lock-in outweigh the
discount at this scale.

---

## 🔴 Immediate Actions  *(address this week)*

> **Threshold note.** This skill's default bar for this bucket is >$100/month. **Nothing
> in this account reaches it** — the entire usage bill is $586.79/month. A fixed $100 bar
> would file a 100%-waste line item under "not urgent", so items are ranked here by
> materiality relative to *this* bill (≥ ~2.5% of baseline usage) rather than by the
> absolute figure. This adjustment is recorded in *Investigation Notes*.

| # | Recommendation | Resource / Service | Est. Monthly Savings | Action |
|---|----------------|--------------------|----------------------|--------|
| 1 | **Do NOT buy the recommended DynamoDB reserved capacity.** Cost Optimization Hub proposes 100 write + 100 read capacity units on a 3-year PartialUpfront term. Its 30-day lookback ended 2026-09-11 and still sees August usage — but the table billed **44,640 WCU-hours and 44,640 RCU-hours (60 WCU + 60 RCU provisioned continuously)** while serving **16 write and 7 read requests in the entire month**, and DynamoDB spend has been **$0.00 since 1 September**. | Amazon DynamoDB — management account, us-east-1 | **+$19.91/mo of new cost avoided** (~$717 over the 3-year term) | Reject recommendations `c981e2ec535b0465` and `cd302718abfbcbf3`. Confirm with the data-science team that the table is intentionally gone; if any DynamoDB table returns, provision it **on-demand**, not provisioned capacity. |
| 2 | **Delete the idle API Gateway cache in us-west-2.** `USW2-ApiGatewayCacheUsage:0.5GB` billed **743.93 hours — continuous 24/7 operation — at $14.88** in August, and is still running in September. Meanwhile all actual API traffic is 11,336 requests in us-east-1 costing **$0.011**. The cache is serving essentially nothing, in a region this reference architecture does not use (standard regions are us-east-1 and us-east-2). | Amazon API Gateway — us-west-2 | **$14.88/mo** ($178.56/yr) | Ask the platform/DevOps team to disable cluster caching on the us-west-2 API stage, then remove the stage if it is a leftover. While there, clear the **6 orphaned Secrets Manager secrets in us-west-2 ($2.40/mo)** — together the region carries ~$17.32/mo with no workload. |
| 3 | **Diagnose 68.1 million S3 requests against 16 GB of stored data.** S3 cost $54.84 in August, of which **storage is only $0.46 (0.8%)** and **requests are $54.35 (99.2%)**: 5,892,460 Tier-1 (PUT/COPY/POST/LIST) and 62,231,019 Tier-2 (GET) requests. That is ~4.25 million requests per GB stored — a polling loop or misconfigured client, not normal access. Lifecycle/tiering policies would save nothing here; the storage is already negligible. | Amazon S3 — primarily us-east-1 | **up to $54.35/mo** (fixable share unknown until diagnosed — see note) | Ask the platform/DevOps team to enable S3 server access logging or query CloudTrail data events on the top buckets for one day to identify the caller, then fix the polling interval. |
| 4 | **Diagnose ~5,400 Cost Explorer API requests/month.** In the **August baseline**, `USE1-APIRequest` billed **$54.11 for exactly 5,411 requests** at $0.01 each — roughly **175 requests/day**, far beyond human dashboard use. The pattern is unchanged in the **September 1–12 run-rate**: **$21.85 across 12 days (~182 requests/day)**, which makes Cost Explorer the **largest single AWS-service line so far this month**, at 20% of September usage. Something automated is polling it. | AWS Cost Explorer — management account | **up to ~$49/mo** (see note) | Ask the platform/DevOps team to identify the scheduled caller (a cost dashboard, Infracost, or a CI job) and cache its results or drop it to daily. For scale: generating **both** of today's FinOps reports cost about **$0.17**. |

> **Note on items 3 and 4.** Billing data proves the cost and the volume but cannot
> identify the caller, so no savings figure is claimed in the totals below. The
> conservative floor for both is **$0 until diagnosed**; the ceiling is the full line
> item. Each needs one short investigation, which is why they are listed as urgent.

---

## 🟡 Short-Term Optimisations  *(next 2–4 weeks)*

| # | Recommendation | Resource / Service | Est. Monthly Savings | Action |
|---|----------------|--------------------|----------------------|--------|
| 1 | **Audit ~44 customer-managed KMS keys.** Key charges are **$44.47 of the $44.68 KMS bill** (requests are $0.21): **$33.49 in us-east-1 (~33 keys)** and **$10.98 in us-east-2 (~11 keys)** at $1/key/month. us-east-2 is the disaster-recovery region and shows almost no other activity, so its 11 keys are the strongest cleanup candidate. | AWS KMS — us-east-1 + us-east-2 | **$10.98/mo** conservative (us-east-2 only); up to $44.47 if the full set is audited | Ask the platform/DevOps team to list customer-managed keys per region and check each for a current consumer. Schedule deletion (7–30 day window) only for keys with no associated resource. **Do not delete a key that still protects stored data** — the data becomes unrecoverable. |
| 2 | **Confirm the single Amazon QuickSight Enterprise author seat is still used.** `QS-User-Enterprise-Month` billed **$24.00** in August and is running at the same rate in September ($9.53 across 12 days). That is one Enterprise author licence at $288/year. | Amazon QuickSight — us-east-1 | **$24.00/mo** ($288/yr) if unused | Ask whoever owns business-intelligence reporting whether that seat is still needed; if the dashboards were a one-off, remove the user. |
| 3 | **Review AWS Security Hub coverage in 15 unused regions.** Security Hub runs paid compliance checks in ~17 regions. us-east-1 accounts for $7.63 (7,633 checks), us-east-2 $0.74 — but **15 further regions each bill exactly 744 checks/month ($0.74 each, ~$11.16 total)** where the organisation runs no workloads. | AWS Security Hub — 15 non-operating regions | **$11.16/mo** ($133.92/yr) | **Confirm compliance posture first.** All-region Security Hub is often deliberate — it is what detects resources created in regions you don't use, and it may be required by the SOC 2 programme that Drata tracks. If the control is not required, disable Security Hub in the unused regions. If it is, record it in `docs/finops/accepted-exceptions.md` so future runs stop re-raising it. |

---

## 🟢 Backlog / Strategic  *(next quarter)*

| # | Recommendation | Resource / Service | Est. Monthly Savings | Action |
|---|----------------|--------------------|----------------------|--------|
| 1 | **Upgrade the Kubernetes cluster still on an end-of-standard-support version.** `USE1-AmazonEKS-Hours:extendedSupport` billed **$1.44744528 across 2.89489056 hours — exactly $0.50/cluster-hour**, charged *on top of* the $0.10/hour standard rate (confirmed: $4.602121251 ÷ 46.02121251 h = $0.10/h). Today it costs almost nothing because that cluster ran under 3 hours all month. **At 24/7 the same surcharge is $365/month per cluster ($4,380/year).** | Amazon EKS — us-east-1 | **$1.45/mo today; $365/mo per cluster of exposure** | Upgrade the cluster to a Kubernetes version still in standard support; the surcharge stops immediately. This is planned work, not an availability reduction, so it is valid for production too. The repo's own `make version-support` guardrail exists to catch exactly this — worth checking why this cluster slipped past it. |
| 2 | **Treat the RDS reserved-instance recommendation with caution.** Cost Optimization Hub proposes a 3-year AllUpfront RI on 1× `db.t3.micro` PostgreSQL, saving **$6.918/month (53%)** against a current $13.14/month. The database is genuinely still running (`InstanceUsage:db.t3.micro` $13.39 in August, ~$15/month pace in September). | Amazon RDS — management account, us-east-1 | **$6.92/mo** ($83/yr) — only if the database is certain to live 3 more years | Buy only if that database is committed for the full term. The DynamoDB case in 🔴 item 1 is the cautionary tale: a 30-day lookback recommended a 3-year lock on a workload that vanished days later. For $83/year, a 3-year commitment on this footprint is marginal. |
| 3 | **Review NAT Gateway usage.** `NatGateway-Hours` $2.43 + `NatGateway-Bytes` $0.066 = **$2.50**, which is **16.7% of combined EC2 + EKS spend ($14.94)** — above the 10% guideline. The hourly charge dominates ($2.43 of $2.50), so the gateways are billed for existing, not for traffic. | Amazon VPC — us-east-1 | **$2.50/mo** | Confirm each NAT Gateway is still needed; where private subnets only reach S3/DynamoDB, VPC **Gateway** endpoints are free and remove the data-processing charge entirely. |
| 4 | **Remove the near-idle load balancer.** `LoadBalancerUsage` billed **$2.18** while `LCUUsage` was **$0.0055** — capacity-unit charges essentially zero, meaning almost no traffic passed through it. | Elastic Load Balancing — us-east-1 | **$2.18/mo** | Confirm the load balancer has a live backend; delete if it is a leftover from a torn-down stack. |
| 5 | **Release the idle Elastic IP address.** `USE1-PublicIPv4:IdleAddress` billed **$0.92** — an allocated public IPv4 address not attached to anything, at $0.005/hour. (`InUseAddress` at $7.32 is legitimate.) | Amazon VPC — us-east-1 | **$0.92/mo** ($11/yr) | Release any Elastic IP with no association. |
| 6 | **Migrate remaining gp2 EBS volumes to gp3.** `EBS:VolumeUsage.gp2` $1.63 vs `EBS:VolumeUsage.gp3` $0.32 — most volumes are already gp3, so this is nearly finished. gp3 is ~20% cheaper per GB with higher baseline IOPS. | Amazon EBS — us-east-1 | **$0.33/mo** | Finish the migration for completeness; the remaining benefit is small. |

---

## Right-Sizing & Idle Resources

**AWS Compute Optimizer returned no recommendations of any kind.** All resource types
(EC2, Lambda, EBS, ECS, ASG, RDS, and 10 others) came back empty.

This is a **readiness gap, not a clean bill of health.** Org-wide enrolment
(`memberAccountsEnrolled: true`) was only switched on **2026-09-11**, and
`numberOfMemberAccountsOptedIn` still reads **0**. Compute Optimizer needs roughly 24
hours after opt-in plus **at least 30 hours of CloudWatch metric history per resource**
before it will emit anything. Re-run this skill after **~2026-09-20** for the first
meaningful right-sizing pass.

**AWS Cost Optimization Hub** is enrolled and returning data — **$13.75/month** total
across 292 recommendations, all of them commitment purchases rather than right-sizing:

| Resource type | Recs | Claimed monthly savings | Assessment |
|---|---:|---:|---|
| `DynamoDbReservedCapacity` | 290 | $6.828 | **Reject** — based on usage that ceased 2026-09-01 (see 🔴 item 1) |
| `RdsReservedInstances` | 2 | $6.918 | Valid, but a 3-year lock for $83/year (see 🟢 item 2) |

Notably, the Hub surfaced **no idle-resource findings at all**, yet this report found an
idle API Gateway cache, an idle Elastic IP, a near-idle load balancer and a fully idle
DynamoDB provisioned-capacity table by reading usage types directly. Do not treat the
Hub as complete coverage at this footprint size.

---

## Savings Plans & Commitment Health

- **Utilisation:** n/a — **no Savings Plans or Reserved Instances are currently owned.**
- **Coverage: 0.0%** *(target > 60%)* — $0 of $36.58 eligible on-demand spend covered
  (August, per Cost Explorer `GetSavingsPlansCoverage`).
- **Estimated wasted commitment spend this month: $0.00** — nothing is committed, so
  nothing can be under-used.
- **Recommended additional commitment: none.**

0% coverage would normally be flagged as a missed discount. **It is the right call here.**
Eligible compute spend is only **$36.58/month**, and much of the EC2 footprint already
runs on **Spot** (`SpotUsage:m5.large`, `t3.medium`, `t3a.medium`, `t2.medium` — $3.07 of
$8.89 EC2 compute), which Savings Plans do not cover and which already discounts more
deeply. A Compute Savings Plan at this scale would lock 1–3 years for single-digit
monthly savings, against a workload that has just demonstrated it can drop 55% in a month.
Revisit only if steady-state compute exceeds ~$200/month.

---

## Service-Specific Waste

**Storage: S3 & EBS.** S3 is a **request-volume** problem, not a storage or tiering one —
see 🔴 item 3. Storage totals just **16.03 GB-Month ($0.37)** in us-east-1 plus 1.89 GB
(us-east-2) and 1.69 GB (us-west-2); Standard-IA and Intelligent-Tiering are already in
use at trivial volumes. **A lifecycle policy would save under $0.20/month — do not
prioritise it.** EBS: mostly gp3 already; $1.63 of gp2 remains (🟢 item 6), plus $1.76 of
snapshots, which is proportionate.

**Networking.** NAT Gateway $2.50 = 16.7% of EC2+EKS spend, above the 10% guideline
(🟢 item 3). Idle Elastic IP $0.92 (🟢 item 5). Cross-region data transfer is negligible
(the largest single flow, `USE1-USE2-AWS-Out-Bytes`, is $0.0089 for 0.89 GB). **Total data
transfer is well under 1% of the bill — far below the 15% flag.** No inter-AZ transfer
charges at all (`USE1-DataTransfer-AZ-Out-Bytes` = $0.00).

**Compute: EC2 & EKS.** EC2 is **$8.89**, of which $5.82 is on-demand `t3.micro` and $3.07
is Spot across four instance families — **Spot adoption is already good practice and needs
no change.** No instance families two or more generations behind were found at material
spend. EKS carries the extended-support surcharge (🟢 item 1); Fargate does not appear at
all, so the Fargate-vs-nodes check does not apply.

**Version-lifecycle surcharges.** **EKS: surcharge confirmed present** — $0.50/cluster-hour
on top of $0.10/hour standard, measured exactly (🟢 item 1). **RDS/Aurora: clean** — no
usage type containing `ExtendedSupport` appears; RDS bills only
`InstanceUsage:db.t3.micro` ($13.39), `RDS:GP2-Storage` ($2.30) and `Aurora:BackupUsage`
($0.0017).

**Compute: Lambda.** Not applicable — **no spend detected** in the baseline month.

**Container Registry: ECR.** $1.47/month, **well below the $20 flag**. No lifecycle-policy
action needed.

**Databases.** **DynamoDB** was the clearest waste in the baseline month — 60 WCU + 60 RCU
provisioned 24/7 for 23 total requests ($20.31) — and has **already been resolved**
(September: $0.00). The live risk is now the stale purchase recommendation (🔴 item 1).
**RDS**: one `db.t3.micro`, no Multi-AZ charges visible, storage $2.30 — proportionate; RI
option at 🟢 item 2. **ElastiCache**: not applicable — no spend detected.

**Analytics & Streaming.** Glue, Kinesis, Redshift Serverless — **not applicable, no
material spend** (Redshift $0.019, below the floor).

**Messaging.** SQS and SNS both **$0.00**; Amazon MQ absent. Not applicable.

**Observability: CloudWatch.** $6.04, of which **$4.08 is `CW:AlarmMonitorUsage`** (≈41
alarms at $0.10) — that is alarm *configuration*, not log volume. **Logs storage is
negligible** (`USE1-VendedLog-Bytes` $0.0045), so the $30/month log-retention flag does not
apply and retention policies would save nothing. No detailed-monitoring charges found.

**Security: Secrets Manager & KMS.** Secrets Manager **$11.73**, below the $50 flag, but
composition matters: **23 secrets in us-east-1 ($9.20)** and **6 in us-west-2 ($2.40)** —
the latter grouped with the idle API Gateway cache in 🔴 item 2. API-request charges appear
in 16 regions at $0.00485 each, which is odd but costs under $0.08/month in total. KMS is
🟡 item 1.

**WAF & Load Balancers.** WAF **$0.0072** — effectively unused, below the floor, nothing to
optimise. ELB: near-idle load balancer at 🟢 item 4.

### Other Services

Every remaining service above the **$5.87/month** materiality floor:

| Service | Aug spend | Assessment |
|---|---:|---|
| Amazon Bedrock — Claude Opus 5 | $206.44 | **Ceased 2026-09-01** ($0.00 in September). Was 35% of the baseline bill. No action available; confirm the stop was intentional — tracked in the companion investigation report. |
| Amazon Bedrock — Claude Sonnet 5 | $58.89 | **Ceased 2026-09-01.** Same as above. |
| AWS Cost Explorer | $55.92 | 🔴 item 4. ($54.11 API requests + $1.81 `CostDataStorage`, which is normal.) |
| Amazon S3 | $54.84 | 🔴 item 3. |
| AWS KMS | $44.68 | 🟡 item 1. |
| Amazon QuickSight | $24.00 | 🟡 item 2. |
| Amazon DynamoDB | $20.31 | 🔴 item 1 — already resolved; the recommendation is the risk. |
| AWS Security Hub | $19.54 | 🟡 item 3. |
| Amazon RDS | $15.69 | 🟢 item 2. |
| Amazon API Gateway | $14.89 | 🔴 item 2. |
| AWS Secrets Manager | $11.73 | Reviewed — us-west-2 portion folded into 🔴 item 2; remainder proportionate. |
| Amazon SageMaker | $10.45 | **Ceased 2026-09-01.** One `ml.m5.xlarge` hosting endpoint ran 45.12 hours in August ($10.38). Reviewed — no action; confirm it was meant to stop. |
| Amazon EC2 — Compute | $8.89 | **Reviewed, no waste found.** Good Spot adoption. |
| Amazon VPC | $8.24 | 🟢 items 3 and 5. |
| EC2 — Other | $6.28 | 🟢 item 6 + snapshots, proportionate. |
| Amazon EKS | $6.05 | 🟢 item 1. |
| AmazonCloudWatch | $6.04 | **Reviewed, no waste found** — alarm configuration, not log sprawl. |

Below the floor and not individually assessed: Claude Haiku 4.5 ($3.37), Route 53 ($3.15),
ELB ($2.19 — still raised at 🟢 item 4), ECR ($1.47), AWS Config ($1.44), End User
Messaging ($0.91), Claude Opus 4.7 ($0.85), Bedrock AgentCore ($0.40), GuardDuty ($0.08),
Redshift ($0.02), WAF ($0.007), SES ($0.005).

---

## Total Savings Opportunity

| Bucket | Count | Est. Monthly Savings |
|--------|------:|---------------------:|
| 🔴 Immediate | 1 firm (+2 to diagnose, 1 loss avoided) | **$14.88** |
| 🟡 Short-Term | 3 | **$46.14** |
| 🟢 Backlog | 6 | **$14.30** |
| **Total (firm)** | **10** | **$75.32/mo · $903.84/yr** |

Held outside the total on purpose:

| Item | Amount | Why excluded |
|---|---:|---|
| S3 request volume (🔴 3) | up to $54.35/mo | Fixable share unknown until the caller is identified |
| Cost Explorer API polling (🔴 4) | up to ~$49.00/mo | Same |
| DynamoDB reserved capacity (🔴 1) | $19.91/mo **avoided** | A cost *not incurred*, not a saving on existing spend |
| KMS beyond us-east-2 (🟡 1) | up to $33.49/mo extra | Needs a per-key consumer audit first |
| EKS extended support at 24/7 (🟢 1) | $365/mo per cluster | Exposure, not current spend ($1.45/mo today) |

**Upper bound if the two diagnoses resolve fully: ~$178.67/month (~$2,144/year)** —
roughly **30% of the baseline usage bill**.

---

## Investigation Notes

1. **Analysis window.** Baseline **2026-08-01 → 2026-08-31** (queried as
   `2026-08-01`→`2026-09-01`, end exclusive), `Estimated: false` — final data. Run-rate
   context **2026-09-01 → 2026-09-12** (queried `2026-09-01`→`2026-09-13`),
   `Estimated: true`. Both on the same usage-charges-only basis.
2. **Cost basis.** `UnblendedCost` filtered to `RECORD_TYPE = Usage` throughout. This
   matters more than usual here: credits currently offset ~100% of usage, so an
   *unfiltered* query returns ≈$0 for every service. Excluded from all figures: the
   **$625.00 Drata** AWS Marketplace subscription (`RECORD_TYPE = Other`), credits
   (−$317.24 in August), tax, and the $7.04 September `FlatRateSubscription` line.
3. **Materiality floor: $5.87/month** — 1% of the $586.79 baseline, being the lower of
   "$20/month or ~1% of the bill".
4. **🔴 threshold deliberately scaled.** The skill's >$100/month bar for Immediate
   Actions is not met by any finding, because the whole usage bill is $586.79/month.
   Items were ranked by share of *this* bill (≥ ~2.5% of baseline) instead. Flagged here
   so the deviation is auditable.
5. **Account → production mapping** (from Cost Explorer `LINKED_ACCOUNT` descriptions;
   classification by account membership, not by tag, per the skill's rule):
   **production** = `binbash-apps-prd`, `binbash-management`, `binbash-shared`,
   `binbash-network`, `binbash-security`; **non-production** = `binbash-apps-devstg`,
   `binbash-data-science`, `binbash-workshop-genai-1/-2/-3`. No schedule-down, Multi-AZ
   removal, or retention reduction was recommended for any production account. In
   practice no such recommendation arose in either group — the idle resources found
   (API Gateway cache, Elastic IP, load balancer, DynamoDB capacity) are waste in any
   environment, not availability trade-offs.
6. **Accepted exceptions: none suppressed.** `docs/finops/accepted-exceptions.md` is
   seeded empty by design, so this first run reports everything. No "accepted, now
   growing" items, since there are no accepted items yet. Candidate for the first row:
   Security Hub's all-region coverage (🟡 item 3), if the compliance programme requires it.
7. **Compute Optimizer enrolment gap.** Org-wide enrolment dated **2026-09-11** with
   `numberOfMemberAccountsOptedIn: 0`; all recommendation types returned empty. Not a
   tool error — insufficient elapsed time. First meaningful data expected after
   ~2026-09-20. **Caution for the next run:** 16 resource-type rows are returned even when
   every one is empty; count recommendations, not rows.
8. **Cost Optimization Hub lookback is stale relative to reality.** Recommendations carry
   `lookback_period_in_days: 30` and `last_refresh_timestamp: 2026-09-11`, so they still
   reflect August usage for workloads that stopped on 1 September. This is the root of the
   DynamoDB warning in 🔴 item 1 and is worth re-checking on every future run rather than
   trusting the Hub's figures directly.
9. **Services reviewed with no waste found:** Amazon EC2 – Compute (good Spot adoption),
   AmazonCloudWatch (alarm configuration, not log sprawl), Amazon ECR (below the $20 flag),
   AWS Secrets Manager us-east-1 portion.
10. **Services skipped for zero or immaterial spend:** AWS Lambda, ElastiCache, AWS Glue,
    Kinesis Data Streams, Redshift Serverless, SQS, SNS, Amazon MQ, AWS Amplify, CloudTrail,
    Cognito, Step Functions, EFS, CloudFront, Elastic Container Registry Public.
11. **Pricing method.** Unit rates were derived from the billing data itself
    (cost ÷ `UsageQuantity`) rather than from the `aws-pricing` tool, which gives the rate
    actually charged to this account instead of a list price. Verified this way:
    EKS standard **$0.10/cluster-hour** ($4.602121251 ÷ 46.02121251 h), EKS extended support
    **$0.50/cluster-hour** ($1.44744528 ÷ 2.89489056 h), Cost Explorer **$0.01/request**
    ($54.11 ÷ 5,411), S3 Tier-1 **$0.005/1,000** and Tier-2 **$0.0004/1,000**. The gp2→gp3
    ~20% figure is the only rule-of-thumb left in the report, on a $0.33/month item.
12. **Savings Plans coverage** returned a single org-wide row with `OnDemandCost` $36.58 and
    `CoveragePercentage` 0.0. No `sp-performance` utilisation query was run, since zero
    coverage means nothing is owned to under-use.
13. **Account IDs deliberately omitted** — this repository is public; accounts are named
    only, per `CLAUDE.md`.
14. **Cost of this run: 5 billed Cost Explorer API requests ≈ $0.05** — four `cost-explorer`
    `USAGE_TYPE` queries plus one `GetSavingsPlansCoverage`, which *is* a Cost Explorer
    operation and *is* billed. Not billed, being separate APIs: Compute Optimizer, Cost
    Optimization Hub, Budgets, `ListCostAllocationTags`, `get_credits`, and `session-sql`
    (local SQLite). Combined with the companion investigation report's 12 billed requests,
    **17 requests ≈ $0.17** for both reports.
15. **MCP-only data path honoured.** Every figure in this report came from the
    `awslabs.billing-cost-management-mcp-server` tools. No AWS CLI, SDK, or shell fallback
    was used for any cost data.
