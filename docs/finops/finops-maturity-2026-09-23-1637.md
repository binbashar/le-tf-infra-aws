# AWS FinOps Maturity Scorecard
**Date:** 2026-09-23
**Account:** `<MANAGEMENT_ACCOUNT_ID>` (binbash-management) — id withheld: this report is committed to a public repository
**Period:** baseline 2026-08-01 → 2026-08-31 (previous full calendar month) · anomaly window 2026-06-25 → 2026-09-23 (91 calendar days, both ends inclusive)

---

## Bottom line

**Stage 0 of 5 — Stage 1 visibility is not yet met.** Gating signal: **S1.4 core tag coverage** — only 3.5% of August usage cost carries `Project` and 0.04% carries `Owner`, the two core keys this account activates, while `Environment` and `Layer`, the keys the IaC applies, appear on billed resources but are Inactive as cost-allocation tags.

---

## Scorecard

| Stage | Name | Grade | Met | Partial | Not met | Unverified |
|---|---|---|---|---|---|---|
| 1 | Visibility & awareness | Partial | 3 | 1 | 1 | 0 |
| 2 | Tactical optimization | Partial | 0 | 3 | 1 | 1 |
| 3 | Strategic optimization | Partial | 0 | 1 | 2 | 2 |
| 4 | Governance & automation | Partial | 2 | 0 | 2 | 2 |
| 5 | FinOps culture | Partial | 1 | 0 | 1 | 3 |

---

## Per-stage detail

Every signal, grouped by stage, with its grade, observed value, and source tool. Spend figures are
August 2026 in-scope usage (**$317.24**, see *Investigation Notes* 2–3); "house opinion" marks a
binbash convention, not an AWS requirement.

### Stage 1 — Visibility & awareness
| Ref | Signal | Grade | Observed value | Source tool |
|---|---|---|---|---|
| S1.1 | Budgets configured | Met | 2 monthly COST budgets ($750 each), each with one FORECASTED alert (>75% and >100%); both alerts in ALARM. The threshold ladder is split across two identical budgets and has no ACTUAL-spend rung | `budgets`, `budget-notifications` |
| S1.2 | Billing alerts enabled | Met | `BILLING_ALERTS` / `cloudwatch` = `ENABLED` | `get-billing-preferences` |
| S1.3 | Cost-allocation tags activated | Met | 8 Active `UserDefined` keys: `Project`, `project`, `Owner`, `owner`, `Component`, `Terraform`, `terraform`, `aws-apn-id` | `list-cost-allocation-tags` |
| S1.4 | Core tag coverage | Not met | `Project`/`project`: 3.48% ($11.05 of $317.24). `Owner`/`owner`: 0.04% ($0.13). Both are below the T1 80% `Partial` band (T1 ≥95% = `Met`, house opinion). `Environment`, `Layer`, `Team`: Inactive, last used 2026-09-01 (present on billed resources). `CostCenter`: absent | `cost-explorer` (TAG), `list-cost-allocation-tags` |
| S1.5 | No stale active tags | Partial | 1 of 8 Active keys stale (T2 >90 days, house opinion): `terraform` (lowercase), last used 2025-04-01 | `list-cost-allocation-tags` |

### Stage 2 — Tactical optimization
| Ref | Signal | Grade | Observed value | Source tool |
|---|---|---|---|---|
| S2.1 | Right-sizing backlog controlled | Partial | Compute Optimizer backlog $27.38/mo = 8.6% of usage (T3 <5%, house opinion). 1 idle RDS instance (data-science, $13.14) and 5 idle DynamoDB tables (shared ×3, apps-devstg ×2, $2.85 each). EC2, RDS and EBS sizing all `Optimized` ($0) | `compute-optimizer` (per member account) |
| S2.2 | Idle resources cleared | Partial | Cost Optimization Hub idle backlog $20.26/mo = 6.4% of usage (T3 <5%, house opinion): 1 `Stop` ($13.14) + 5 `Delete` ($7.12). Same six resources as S2.1, so the two figures are never summed | `cost-optimization` |
| S2.3 | Commitment coverage | Not met | Savings Plans cover 0% of $36.58 eligible on-demand spend. RIs cover 0% of 559.8 running hours (T4 ≥60%, house opinion) | `sp-performance`, `ri-performance` |
| S2.4 | Commitment utilisation | Unverified | No Savings Plans or Reserved Instances owned, so utilisation is undefined | `sp-performance`, `ri-performance` |
| S2.5 | Storage lifecycle in use | Partial | S3 Standard = 98.95% of S3 storage spend ($0.451 of $0.456) (T9 <95%, house opinion). Standard-IA and Intelligent-Tiering are present at ~1%. Storage is $0.46 of $54.84 total S3 usage | `cost-explorer` (USAGE_TYPE) |

### Stage 3 — Strategic optimization
| Ref | Signal | Grade | Observed value | Source tool |
|---|---|---|---|---|
| S3.1 | Graviton adoption | Not met | 0% of $8.89 EC2 compute (T6, house opinion): t3.micro $5.82, t3.medium $2.30, m5.large $0.45, t3a.medium $0.27, t2.medium $0.05. No Graviton family | `cost-explorer` (INSTANCE_TYPE) |
| S3.2 | Lambda on `arm64` | Unverified | Lambda compute billed $0.00 (free tier), so the T6 spend ratio is undefined. Only the x86 `Lambda-GB-Second` usage type appears; no `Lambda-GB-Second-ARM` | `cost-explorer` (USAGE_TYPE) |
| S3.3 | Lambda sizing tuned | Not met | 1 function analyzed org-wide (shared): `NotOptimized`, recommended 256 MB → 320 MB, $0.00 savings | `compute-optimizer` (per member account) |
| S3.4 | NAT vs VPC endpoints | Partial | *Directional only.* NAT data processing $0.07 = 0.02% of usage, below T10's 5% (house opinion). No interface VPC endpoint usage type billed. NAT hours $2.43 | `cost-explorer` (USAGE_TYPE) |
| S3.5 | Autoscaling posture | Unverified | Compute Optimizer returned no Auto Scaling group analyses for the payer, shared or apps-devstg | `compute-optimizer` (per member account) |

### Stage 4 — Governance & automation
| Ref | Signal | Grade | Observed value | Source tool |
|---|---|---|---|---|
| S4.1 | Consolidated billing | Met | 10 accounts under the payer (9 linked + payer) | `list-account-associations` |
| S4.2 | Cost Categories defined | Not met | 0 cost categories | `list-cost-category-definitions` |
| S4.3 | Showback / chargeback | Not met | 0 billing groups, 0 custom line items. The 2 pricing plans returned are AWS-managed defaults | `list-billing-groups`, `list-custom-line-items`, `list-pricing-plans` |
| S4.4 | RI/SP sharing deliberate | Met | `default` = `ENABLED`, `open-sharing` = `ENABLED`, all 10 accounts `ENABLED`. Unchanged 2025-10 → 2026-09 | `get-billing-preferences` (`RI_SHARING`, `RI_SHARING_HISTORY`) |
| S4.5 | Tag Policies enforced | Unverified | Organizations API — not in this MCP | — |
| S4.6 | Preventive SCPs | Unverified | Organizations API — not in this MCP | — |

### Stage 5 — FinOps culture
| Ref | Signal | Grade | Observed value | Source tool |
|---|---|---|---|---|
| S5.1 | Anomaly detection active | Met | 3 anomalies in the window, all from one monitor: QuickSight 09-14→09-22 ($7.11); Claude Haiku 4.5 on Bedrock 09-15 ($7.60); Bedrock Mistral/Nova 09-19 ($2.84) | `cost-anomaly` |
| S5.2 | Anomalies actually triaged | Not met | 0 of 3 anomalies carry feedback: 0% vs T8 ≥50% (house opinion) | `cost-anomaly` |
| S5.3 | Commitment renewal hygiene | Unverified | No commitments owned: no Savings Plans in any state, no RIs (T7) | `sp-explorer`, `ri-performance` |
| S5.4 | Unit economics tracked | Unverified | Not derivable from billing data | — |
| S5.5 | Review cadence & cost in code review | Unverified | Process, not billing data | — |

---

## What this scorecard cannot see

- **S2.4 — Commitment utilisation?** No Savings Plans or Reserved Instances are owned, so there is
  nothing to utilise. Is running without commitments a deliberate decision for this footprint?
- **S3.2 — Lambda on arm64?** Lambda compute bills $0.00, so the spend ratio is undefined. Do
  Lambda functions default to `arm64` in IaC?
- **S3.5 — Autoscaling posture?** Compute Optimizer had no Auto Scaling group to analyse. Do the
  workloads that scale (e.g. EKS node groups) run long enough to be analysed, and are their scaling
  policies reviewed?
- **S4.5 — Tag Policies enforced?** Does AWS Organizations enforce a Tag Policy on this account?
- **S4.6 — Preventive SCPs in place?** Do Service Control Policies block untagged resource creation
  or other high-risk actions?
- **S5.3 — Commitment renewal hygiene?** No commitments are owned. When commitments are bought, who
  reviews expiry and renewal?
- **S5.4 — Unit economics tracked?** Does the organization measure cost per customer, transaction,
  or feature?
- **S5.5 — Review cadence & cost in code review?** Is there a recurring FinOps review, and is cost
  considered during code/PR review?

> This scorecard grades what AWS **bills**, not what this organization
> **runs**. A low Stage 4 or Stage 5 grade may mean "not visible in billing
> data" rather than "not governed".

---

## Roadmap to Stage 1

Stage 0's roadmap is Stage 1 alone. Gating signal first, then ascending by signal ref.

| # | Signal | Grade | Effort | Owner type | Observed $/mo |
|---|---|---|---|---|---|
| 1 | S1.4 Core tag coverage | Not met | M | FinOps / Platform | |
| 2 | S1.5 No stale active tags | Partial | S | FinOps | |

> **Review note (added after the run).** Tagging alone cannot clear S1.4 under this report's
> denominator. At least $76.98 (24.3%) of August usage bills at account level, with no resource
> to tag (Investigation Note 6), which caps coverage near 76%, below T1's 80% `Partial` band.
> Measured over taggable spend only ($240.26 at most), `Project` coverage is still about 4.6%, so
> the Stage 0 placement holds either way. The first S1.4 action is activating `Environment` and
> `Layer` as cost-allocation tags, since the IaC already applies both. From aws-finops 1.3.0 the
> skill measures T1 over taggable spend and names that action itself, so the next run grades it
> that way.

---

## Handoffs

- Dollar-quantified savings → `/aws-finops-optimize`
- Where the money went, anomalies, forecast → `/aws-finops-investigate`
- Design-time review of IaC against the Cost Optimization pillar → `/well-architected-iac-review`

---

## Investigation Notes

1. **Periods.** `baseline_period` 2026-08-01..2026-09-01 (end exclusive; previous full calendar
   month). `anomaly_window` 2026-06-25..2026-09-23 (start = run date − 90 days; both ends inclusive
   per `cost-anomaly`, so 91 calendar days; local-date end).
2. **Cost basis.** `UnblendedCost` with the skill's cost-scope filter (`RECORD_TYPE` ∈ {`Usage`,
   `DiscountedUsage`, `SavingsPlanCoveredUsage`} AND `BILLING_ENTITY` = `AWS`) gives **$317.24** for
   August 2026. The full August mix (`RECORD_TYPE` × `BILLING_ENTITY`) is:
   - Usage/AWS $317.24
   - Usage/AWS Marketplace $269.55
   - Other/AWS Marketplace $625.00
   - Credit/AWS −$317.24
   - Tax $0.00

   There is no `DiscountedUsage` or `SavingsPlanCoveredUsage`, so the RI `DiscountedUsage` asymmetry
   does not apply this run. Credits offset ~100% of in-scope usage; grades use gross usage, as
   *Cost scope* requires.
3. **Cost-scope caveat: Bedrock inference is excluded.** All $269.55 of Usage/AWS Marketplace is
   Amazon Bedrock third-party model inference: Claude Opus 5 $206.44, Claude Sonnet 5 $58.89,
   Claude Haiku 4.5 $3.37, Claude Opus 4.7 $0.85, others <$0.01. The `BILLING_ENTITY` = `AWS`
   clause therefore removes 45.9% of August resource consumption. The $625.00 SaaS subscription is
   `RECORD_TYPE` = `Other` and is already excluded by the `RECORD_TYPE` clause. With Bedrock in
   scope, T3's 5% threshold would be $29.34 instead of $15.86, and S2.1 ($27.38) and S2.2 ($20.26)
   would both grade `Met`. The Stage 0 placement would not change.
4. **House-opinion thresholds applied** (binbash convention, not AWS requirements): T1 (S1.4),
   T2 (S1.5), T3 (S2.1, S2.2), T4 (S2.3), T6 (S3.1, S3.2), T7 (S5.3), T8 (S5.2), T9 (S2.5),
   T10 (S3.4). T5 (S2.4) is definitional.
5. **S1.1.** `budgets` returns no notification data, so notifications were read with
   `budget-notifications`.
6. **S1.4 keys evaluated.**
   - Evaluated: `Project` (with lowercase `project`) and `Owner` (with `owner`), the core keys this
     account activates. Coverage is the union of each case pair.
   - Not evaluable: `Environment`, `Layer` and `Team` are Inactive, so Cost Explorer cannot group by
     them, although they appear on billed resources (last used 2026-09-01). `CostCenter` does not exist.
   - Coverage ceiling: at least $76.98 (24.3%) of August usage bills at account level with no
     resource to tag: Cost Explorer API $55.92, Security Hub $19.54, Config $1.44, GuardDuty $0.08.
     This classification comes from AWS billing behaviour, not an MCP field. Tagging alone therefore
     caps coverage near 76%, below both T1 bands.
7. **S1.5.** The stale key is `terraform` (lowercase), last used 2025-04-01.
8. **Compute Optimizer scope.**
   - A payer-account call (no `account_ids`, default region) returned zero recommendations, because
     Compute Optimizer returns a management account's own resources unless a member account id is
     passed (one per request).
   - This run queried member accounts one at a time in us-east-1, the only region with EC2, RDS,
     Lambda, EC2-Other or ECS spend in August (per Cost Explorer by `REGION`):
     - EC2, EBS and RDS sizing: shared, apps-devstg, data-science
     - Idle: shared, apps-devstg, data-science, apps-prd, network, security
     - Lambda: payer, shared, apps-devstg, apps-prd, security, data-science
     - ASG: payer, shared, apps-devstg
   - Two extra Cost Explorer calls (`LINKED_ACCOUNT` × `SERVICE`, `LINKED_ACCOUNT` × `REGION`)
     targeted those queries.
9. **S2.1 vs S2.2 overlap.** Both backlogs are the same six resources and are never summed. Prices
   for each idle DynamoDB table differ by source:
   - Compute Optimizer: $2.85/mo list, $1.63 after discounts
   - Cost Optimization Hub: $1.42

   S2.1 uses Compute Optimizer's list figure and S2.2 the Hub's. Compute Optimizer's after-discount
   total ($21.27) does not change the grade. The Hub also lists 1 `MigrateToGraviton` ($1.03/mo) and
   438 `PurchaseReservedInstances` ($4.00/mo total) recommendations; neither is idle or right-sizing,
   so both are excluded from S2.2.
10. **S2.4 / S5.3.** No Savings Plans in any state and no Reserved Instances are owned.
    `get_savings_plans_utilization` returned `DataUnavailableException` and RI utilisation returned
    an empty set. Both are expected with no commitments and are recorded here, not as probe
    failures. The T7 "no commitments owned" carve-out is applied to both signals.
11. **S2.5.** T9 was evaluated on S3 `TimedStorage` usage types only ($0.456, including S3 Vectors).
    Storage is 0.8% of S3 usage ($54.84, of which requests are $54.37), so the signal is immaterial
    at this storage volume.
12. **S3.2.** Lambda compute billed $0.00 in August, so the ratio is undefined: `Unverified`, not
    `Not met`.
13. **S3.3.** The single outstanding recommendation is a memory upsize with no saving. It grades
    `Not met` under "none outstanding" as written.
14. **S3.4.** Directional only (*Measurement caveats*). NAT data processing cannot be attributed to
    a destination, and gateway endpoints (S3, DynamoDB) leave no billing line.
15. **S3.5.** The empty result means nothing was analysed, so it grades `Unverified`, not `Met`.
16. **S5.1 / S5.2.** The quiet-account carve-out did not trigger: 3 anomalies were returned. All
    three fall between 2026-09-14 and 2026-09-22, at most nine days old at run time, so S5.2's
    `Not met` reflects a short triage window.
17. **S4.2 / S4.3.** There are no cost categories, so the `ProcessingStatus: APPLIED` caveat does not
    arise. `list-pricing-plans` returns two AWS-managed read-only plans (`BasicPricingPlan`,
    `Passthrough`) on every account; they are not evidence of showback.
18. **Account id withheld** (public repository). The scorecard block carries
    `<MANAGEMENT_ACCOUNT_ID>`. A future Phase 0 must compare against that token, or it will skip
    the trend comparison as an account mismatch.
19. **First run.** No prior `docs/finops/finops-maturity-*.md` exists, so the *Movement since*
    section is omitted.
20. **Cost of this run.** 15 Cost Explorer-billed requests (~$0.15).

---

## Scorecard block

```yaml
schema: bb-finops-maturity/v1
generated: 2026-09-23
account: "<MANAGEMENT_ACCOUNT_ID>"
baseline_period: 2026-08-01..2026-09-01   # end exclusive
anomaly_window: 2026-06-25..2026-09-23
stage: 0                 # 0 = Stage 1 is not yet Met
gating_signal: S1.4
blocked_stage: null
stages:
  - id: 1
    name: visibility
    grade: partial
    signals: {met: 3, partial: 1, not_met: 1, unverified: 0}
  - id: 2
    name: tactical
    grade: partial
    signals: {met: 0, partial: 3, not_met: 1, unverified: 1}
  - id: 3
    name: strategic
    grade: partial
    signals: {met: 0, partial: 1, not_met: 2, unverified: 2}
  - id: 4
    name: governance
    grade: partial
    signals: {met: 2, partial: 0, not_met: 2, unverified: 2}
  - id: 5
    name: culture
    grade: partial
    signals: {met: 1, partial: 0, not_met: 1, unverified: 3}
unverified: [S2.4, S3.2, S3.5, S4.5, S4.6, S5.3, S5.4, S5.5]
```
