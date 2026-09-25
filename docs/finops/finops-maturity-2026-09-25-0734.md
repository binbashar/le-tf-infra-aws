# AWS FinOps Maturity Scorecard
**Date:** 2026-09-25
**Account:** binbash-management (…7950)
**Period:** baseline 2026-08-01 → 2026-08-31 (previous full calendar month) · anomaly window 2026-06-27 → 2026-09-25 (trailing 90 days; 91 calendar days, both ends inclusive)

---

## Bottom line

**Stage 0 of 5 — Stage 1 visibility is not yet met.** Gating signal: **S1.4 core tag coverage** — only 2.2% of taggable August usage carries `Project` and 0.03% carries `Owner`, the two core keys this account activates, while `Environment` and `Layer`, the keys the IaC applies, sit on billed resources as Inactive cost-allocation tags; activating them is the first step to clearing it.

---

## Scorecard

| Stage | Name | Grade | Met | Partial | Not met | Unverified | N/A |
|---|---|---|---|---|---|---|---|
| 1 | Visibility & awareness | Partial | 3 | 1 | 1 | 0 | 0 |
| 2 | Tactical optimization | Met | 2 | 0 | 0 | 0 | 3 |
| 3 | Strategic optimization | N/A | 0 | 0 | 0 | 0 | 5 |
| 4 | Governance & automation | Partial | 2 | 0 | 2 | 2 | 0 |
| 5 | FinOps culture | Partial | 1 | 0 | 1 | 2 | 1 |

---

## Movement since 2026-09-23

The prior report is a `bb-finops-maturity/v1` block, graded by an **older method**: Bedrock model
usage did not yet count as usage, T1 had no taggable denominator, and `N/A` did not exist. Both
runs read the same August baseline, and no billing practice changed between them. This run was
deliberately made before any tag activation, so every movement below is **methodological**,
not a change in practice. Counts read Met / Partial / Not met / Unverified / N/A.

| Stage | Prior grade (2026-09-23) | Current grade | Movement |
|---|---|---|---|
| 1 | Partial (3 / 1 / 1 / 0 / –) | Partial (3 / 1 / 1 / 0 / 0) | Unchanged. S1.4 is still `Not met`: the same $11.05 carries `Project`, now over a $509.81 taggable base instead of $317.24 |
| 2 | Partial (0 / 3 / 1 / 1 / –) | Met (2 / 0 / 0 / 0 / 3) | Advanced by method. S2.1 and S2.2 went `Partial` → `Met` because Bedrock inference now counts in T3's denominator ($317.24 → $586.79). S2.3 (`Not met`) and S2.5 (`Partial`) moved to `N/A`: the materiality floor is new, and the spend itself did not change. S2.4 followed S2.3 from `Unverified` to `N/A` |
| 3 | Partial (0 / 1 / 2 / 2 / –) | N/A (0 / 0 / 0 / 0 / 5) | Moved to `N/A`: every stage-3 spend base is under the new $50 floor. The spend did not change |
| 4 | Partial (2 / 0 / 2 / 2 / –) | Partial (2 / 0 / 2 / 2 / 0) | Unchanged |
| 5 | Partial (1 / 0 / 1 / 3 / –) | Partial (1 / 0 / 1 / 2 / 1) | Unchanged grade. S5.3 followed S2.3 from `Unverified` to `N/A`. Anomalies rose from 3 to 4, still with none triaged |

Overall: **Stage 0 → Stage 0**, gate **S1.4 → S1.4**. The account match with the prior report is
assumed (Investigation Note 19).

---

## Per-stage detail

Every signal, grouped by stage, with its grade, observed value, and source tool. Spend figures are
August 2026 usage under the usage filter (**$586.79**, see *Investigation Notes* 2–3); "house
opinion" marks a binbash convention, not an AWS requirement. An `N/A` signal's observed value is
its spend base against the T11 floor ($50/month, house opinion).

### Stage 1 — Visibility & awareness
| Ref | Signal | Grade | Observed value | Source tool |
|---|---|---|---|---|
| S1.1 | Budgets configured | Met | 2 monthly `COST` budgets ($750 each), each with one `FORECASTED` alert (>75% and >100%). Both alerts are in `ALARM` and both budgets are `EXCEEDED` ($905.63 actual month-to-date). The threshold ladder is split across two identical budgets and has no `ACTUAL`-spend rung | `budgets`, `budget-notifications` |
| S1.2 | Billing alerts enabled | Met | `BILLING_ALERTS` / `cloudwatch` = `ENABLED` | `get-billing-preferences` |
| S1.3 | Cost-allocation tags activated | Met | 8 Active `UserDefined` keys: `Project`, `project`, `Owner`, `owner`, `Component`, `Terraform`, `terraform`, `aws-apn-id` | `list-cost-allocation-tags` |
| S1.4 | Core tag coverage | Not met | Over **taggable** usage ($509.81): `Project`/`project` 2.17% ($11.05), `Owner`/`owner` 0.03% ($0.13). Both are below T1's 80% `Partial` band (T1 ≥95% = `Met`, house opinion). 146 Inactive keys appear on billed resources in the last 90 days, among them `Environment`, `environment`, `Layer`, `Stage`, `Team`, `team`, `iamPrincipal/Environment` and `iamPrincipal/Layer` (full list in Investigation Note 7). `CostCenter` or an equivalent: absent | `cost-explorer` (TAG), `list-cost-allocation-tags` |
| S1.5 | No stale active tags | Partial | 1 of 8 Active keys is stale (T2 >90 days, house opinion): `terraform` (lowercase), last used 2025-04-01 | `list-cost-allocation-tags` |

### Stage 2 — Tactical optimization
| Ref | Signal | Grade | Observed value | Source tool |
|---|---|---|---|---|
| S2.1 | Right-sizing backlog controlled | Met | Compute Optimizer backlog is $27.38/mo at list price, 4.67% of $586.79 usage (T3 <5%, house opinion), over 9 analysed resources. All of it is idle: `database-1` (RDS, binbash-data-science (…4519)) at $13.14, and 5 DynamoDB tables at $2.85 each, 3 in binbash-shared (…4258) and 2 in binbash-apps-devstg (…3444). EC2, EBS, RDS and Lambda sizing: $0 | `compute-optimizer` (per account, us-east-1) |
| S2.2 | Idle resources cleared | Met | Cost Optimization Hub idle backlog is $21.27/mo, 3.63% of usage (T3 <5%, house opinion): 1 `Stop` ($13.14) plus 5 `Delete` ($8.13). These are the same six resources as S2.1, so the two are never summed | `cost-optimization` |
| S2.3 | Commitment coverage | N/A — immaterial | Commitment-eligible spend is $49.97/mo, under the $50 floor (T11): $36.58 eligible for Savings Plans plus $13.39 of RDS on-demand eligible for Reserved Instances. Coverage is 0% | `sp-performance`, `ri-performance` |
| S2.4 | Commitment utilisation | N/A — immaterial | No commitments are owned (no Savings Plans in any state, no Reserved Instances), and S2.3 is `N/A` (T5) | `sp-explorer`, `ri-performance` |
| S2.5 | Storage lifecycle in use | N/A — immaterial | S3 storage is $0.46/mo, under the $50 floor (T11), out of $54.84 total S3 usage, of which requests are $54.35 | `cost-explorer` (USAGE_TYPE) |

### Stage 3 — Strategic optimization
| Ref | Signal | Grade | Observed value | Source tool |
|---|---|---|---|---|
| S3.1 | Graviton adoption | N/A — immaterial | EC2 instance compute $8.89/mo, under the $50 floor (T11) | `cost-explorer` (SERVICE) |
| S3.2 | Lambda on `arm64` | N/A — immaterial | Lambda $0.00/mo, under the $50 floor (T11) | `cost-explorer` (SERVICE) |
| S3.3 | Lambda sizing tuned | N/A — immaterial | Lambda $0.00/mo, under the $50 floor (T11) | `cost-explorer` (SERVICE) |
| S3.4 | NAT vs VPC endpoints | N/A — immaterial | NAT data processing (`NatGateway-Bytes`) $0.07/mo, under the $50 floor (T11) | `cost-explorer` (USAGE_TYPE) |
| S3.5 | Autoscaling posture | N/A — immaterial | EC2 instance compute $8.89/mo, under the $50 floor (T11) | `cost-explorer` (SERVICE) |

### Stage 4 — Governance & automation
| Ref | Signal | Grade | Observed value | Source tool |
|---|---|---|---|---|
| S4.1 | Consolidated billing | Met | 10 accounts under the payer (9 linked + payer) | `list-account-associations` |
| S4.2 | Cost Categories defined | Not met | 0 cost categories | `list-cost-category-definitions` |
| S4.3 | Showback / chargeback | Not met | 0 billing groups, 0 custom line items. The 2 pricing plans returned are AWS-managed defaults | `list-billing-groups`, `list-custom-line-items`, `list-pricing-plans` |
| S4.4 | RI/SP sharing deliberate | Met | `default` = `ENABLED`, `open-sharing` = `ENABLED`, all 10 accounts `ENABLED`. Unchanged from 2025-10 to 2026-09 | `get-billing-preferences` (`RI_SHARING`, `RI_SHARING_HISTORY`) |
| S4.5 | Tag Policies enforced | Unverified | Organizations API — not in this MCP | — |
| S4.6 | Preventive SCPs | Unverified | Organizations API — not in this MCP | — |

### Stage 5 — FinOps culture
| Ref | Signal | Grade | Observed value | Source tool |
|---|---|---|---|---|
| S5.1 | Anomaly detection active | Met | 4 anomalies in the window, all from one monitor: QuickSight 09-14→09-22 ($7.11); Claude Haiku 4.5 on Bedrock 09-15 ($7.60); Amazon Bedrock, Mistral/Nova, 09-19 ($2.84); Amazon Bedrock, Mistral/Llama, 09-23 ($7.68) | `cost-anomaly` |
| S5.2 | Anomalies actually triaged | Not met | 0 of 4 anomalies carry feedback: 0% vs T8 ≥50% (house opinion) | `cost-anomaly` |
| S5.3 | Commitment renewal hygiene | N/A — immaterial | No commitments are owned, and S2.3 is `N/A` (T7) | `sp-explorer`, `ri-performance` |
| S5.4 | Unit economics tracked | Unverified | Not derivable from billing data | — |
| S5.5 | Review cadence & cost in code review | Unverified | Process, not billing data | — |

---

## What this scorecard cannot see

- **S4.5 — Tag Policies enforced?** Does AWS Organizations enforce a Tag Policy on this account?
  (A pointer for whoever answers: this repository's `management/global/organizations` layer
  defines no `TAG_POLICY`.)
- **S4.6 — Preventive SCPs in place?** Do Service Control Policies block untagged resource
  creation or other high-risk actions? (The same layer defines four Service Control Policies in
  `policies_scp.tf`; whether they cover this question is for a human to judge.)
- **S5.4 — Unit economics tracked?** Does the organization measure cost per customer, transaction,
  or feature?
- **S5.5 — Review cadence & cost in code review?** Is there a recurring FinOps review, and is cost
  considered during code/PR review?

`N/A` signals are not listed here: they were seen, and are immaterial.

> This scorecard grades what AWS **bills**, not what this organization
> **runs**. A low Stage 4 or Stage 5 grade may mean "not visible in billing
> data" rather than "not governed".

---

## Roadmap to Stage 1

Stage 0's roadmap is Stage 1 alone. Gating signal first, then ascending by signal ref.

| # | Signal | Grade | Action | Effort | Owner type | Observed $/mo |
|---|---|---|---|---|---|---|
| 1 | S1.4 Core tag coverage | Not met | Activate `Environment` and `Layer` as cost-allocation tags. The IaC already applies both, and they are on billed resources. Activate their `iamPrincipal/` counterparts too, which is how IAM-principal cost allocation reaches Bedrock inference (53% of taggable usage). Request a backfill so the baseline month becomes measurable | M | FinOps / Platform | |
| 2 | S1.5 No stale active tags | Partial | Deactivate the stale lowercase `terraform` key (last used 2025-04-01) | S | FinOps | |

---

## Handoffs

- Dollar-quantified savings → `/aws-finops-optimize`
- Where the money went, anomalies, forecast → `/aws-finops-investigate`
- Design-time review of IaC against the Cost Optimization pillar → `/well-architected-iac-review`

---

## Investigation Notes

1. **Periods.** `baseline_period` 2026-08-01..2026-09-01 (end exclusive; previous full calendar
   month). `anomaly_window` 2026-06-27..2026-09-25: the start is the run date minus 90 days, and
   `cost-anomaly` treats both ends as inclusive, so it spans 91 calendar days, the same convention
   as the 09-23 run. Month-to-date 2026-09-01..2026-09-25 (end exclusive) is used only as a run-rate
   signal (note 21).
2. **Cost basis.** `UnblendedCost` under the usage filter: `RECORD_TYPE` ∈ {`Usage`,
   `DiscountedUsage`, `SavingsPlanCoveredUsage`}, AND either `BILLING_ENTITY` ∈ {`AWS`, `AISPL`} or
   `SERVICE` ∈ the 15 Bedrock model services in note 3. August usage is **$586.79**: $317.24
   AWS-billed plus $269.55 Bedrock model inference. The full August mix (`RECORD_TYPE` ×
   `BILLING_ENTITY`) is:
   - Usage / AWS $317.24
   - Usage / AWS Marketplace $269.55
   - Other / AWS Marketplace $625.00
   - Credit / AWS −$317.24
   - Tax $0.00

   There is no `DiscountedUsage`, `SavingsPlanCoveredUsage` or `RIFee`, so the RI asymmetry does
   not apply. Credits offset exactly the AWS-billed usage and none of the Marketplace charges.
   Grades use gross usage, as *Cost scope* requires.
3. **Marketplace split.**
   - **Kept as usage:** Bedrock model services, found in step 1 of the filter.
     - August: $269.55 across 6 services — Claude Opus 5 $206.44, Claude Sonnet 5 $58.89, Claude
       Haiku 4.5 $3.37, Claude Opus 4.7 $0.85; Claude Opus 4.8 and Cohere Embed Model 3 -
       Multilingual <$0.01 each.
     - September to date: $18.24 across 14 services — Claude Haiku 4.5 $10.55, OpenAI GPT-5.6
       Terra $3.63, GPT-5.6 Sol $1.97, Claude Sonnet 4.6 $1.40, GPT-5.6 Luna $0.57; 9 others
       <$0.07 each.
     - The filter lists the union of both months' names.
   - **Excluded Marketplace usage: $0.00 in both periods.** The only non-Bedrock Marketplace usage
     service is `demo_v1`, at $0.00 in August.
   - The $625.00 SaaS subscription is `RECORD_TYPE` = `Other`, which is not usage.
4. **Account-level services left out of T1's denominator** (August): AWS Cost Explorer $55.92,
   AWS Security Hub $19.54, AWS Config $1.44, Amazon GuardDuty $0.08, for $76.98 in all. Taggable
   usage is $586.79 − $76.98 = **$509.81**. No new account-level candidate was verified this run.
   Amazon QuickSight ($24.00 in August) bills a flat amount consistent with a per-user
   subscription and may be one; check before adding it to the list.
5. **House-opinion thresholds applied** (binbash conventions, not AWS requirements): T1 (S1.4),
   T2 (S1.5), T3 (S2.1, S2.2), T8 (S5.2) and T11 (every `N/A`). T4, T6, T9 and T10 were not
   reached, because their signals are `N/A`. T5 (definitional) and T7 resolved to `N/A` through
   S2.3.
6. **S1.1.** `budgets` returns no notification data, so notifications were read with
   `budget-notifications`.
7. **S1.4 keys.**
   - **Evaluated:** `Project` with lowercase `project`, and `Owner` with `owner`. These are the core
     keys this account activates, and coverage is the union of each case pair. Lowercase `project`
     and `owner` carry no August cost. `CostCenter` has no equivalent.
   - **Not evaluable:** 146 keys (133 `UserDefined`, 13 `AWSGenerated`) are Inactive but have a
     `LastUsedDate` in the last 90 days. They are on billed resources, and Cost Explorer cannot
     group by them. The last-used month is 2026-08 or 2026-09 for all of them.
     - Core-convention equivalents (6): `Environment`, `environment`, `Stage`, `Layer`, `Team`, `team`.
     - IAM-principal keys (14): `iamPrincipal/Action`, `/Actor`, `/Branch`, `/Commit`,
       `/Environment`, `/EventName`, `/GitHub`, `/Job`, `/Layer`, `/Repository`, `/RunId`,
       `/Terraform`, `/TriggeringActor`, `/Workflow`.
     - AWS-generated (13): `aws:autoscaling:groupName`, `aws:backup:source-resource`,
       `aws:cloudformation:logical-id`, `aws:cloudformation:stack-id`,
       `aws:cloudformation:stack-name`, `aws:createdBy`, `aws:ec2:fleet-id`,
       `aws:ec2launchtemplate:id`, `aws:ec2launchtemplate:version`, `aws:eks:cluster-name`,
       `aws:secretsmanager:owningService`, `aws:ssmmessages:session-id`, `aws:ssmmessages:target-id`.
     - Kubernetes and controller labels (66): `CSIVolumeName`, `KubernetesCluster`,
       `app.kubernetes.io/{component,instance,managed-by,name,part-of,version}`,
       `apps.kubernetes.io/pod-index`, `batch.kubernetes.io/{controller-uid,job-name}`, `chart`,
       `cluster.k8s.amazonaws.com/name`, `control-plane`, `controller-revision-hash`,
       `controller-uid`, `ebs.csi.aws.com/{cluster,cluster-name}`, `eks.amazonaws.com/component`,
       `eks:{cluster-name,eni:owner,nodegroup-name}`, `elbv2.k8s.aws/{cluster,resource}`,
       `gateway.envoyproxy.io/{owning-gateway-name,owning-gateway-namespace}`,
       `gateway.networking.k8s.io/{gateway-class-name,gateway-name}`, `helm.sh/chart`, `heritage`,
       `ingress.k8s.aws/{resource,stack}`, `job-name`, `jobLabel`, `k8s-app`,
       `k8s.io/cluster-autoscaler/{bb-apps-devstg-eks-1ry,bb-apps-devstg-eks-demoapps,bb-apps-devstg-eks-lkp,bb-apps-devstg-eks-v117-primary,enabled}`,
       `karpenter.k8s.aws/ec2nodeclass`, `karpenter.sh/{discovery,managed-by}`, `kgateway`,
       `kubernetes.io/cluster/{bb-apps-devstg-eks-demoapps,cluster-kops-1.k8s.devstg.binbash.aws,cluster-kops-1.k8s.prd.binbash.aws}`,
       `kubernetes.io/created-for/{pv/name,pvc/name,pvc/namespace}`,
       `kubernetes.io/role/{elb,internal-elb}`, `node.k8s.amazonaws.com/{createdAt,instance_id}`,
       `operator.prometheus.io/{name,shard}`, `pod-template-generation`, `pod-template-hash`,
       `prometheus`, `release`, `rollouts-pod-template-hash`, `run`,
       `service.k8s.aws/{resource,stack}`, `statefulset.kubernetes.io/pod-name`,
       `topology.kubernetes.io/region`.
     - Other user-defined (47): `Agent`, `AgentName`, `AmazonECSManaged`, `ApprovedAMI`,
       `Attributes`, `Author`, `Automation`, `Backup`, `Client`, `Cluster`, `Created-From`,
       `Created-from`, `CreatedBy`, `Delete`, `EvaluationType`, `FMManaged`, `IsProtected`,
       `ManagedBy`, `Managedby`, `ManagedByAmazonSageMakerResource`, `ManagedStackSource`, `Name`,
       `Namespace`, `PeeringAccepter`, `PeeringRequester`, `Pipeline`, `Purpose`, `purpose`,
       `Repository`, `ScheduleStartDaily`, `ScheduleStopDaily`, `Service`, `Side`, `Subject`,
       `Type`, `VercelInstallId`, `WorkloadName`, `app`, `aws-cdk:auto-delete-objects`, `creator`,
       `ghr:Application`, `ghr:environment`, `lambda-console:blueprint`, `lambda:createdBy`,
       `sqlworkbench-resource-owner`, `terraform-aws-modules`, `validation`.
   - **Coverage ceiling:** T1 now excludes account-level spend, so the ~76% ceiling noted on
     2026-09-23 no longer applies. The largest block of taggable usage is Bedrock inference: $269.55,
     53%.
8. **S1.5.** The stale key is `terraform` (lowercase), last used 2025-04-01. Every other Active
   key was last used 2026-09-01.
9. **Compute Optimizer coverage.** In August only us-east-1 carried spend on the services Compute
   Optimizer analyses (per Cost Explorer `LINKED_ACCOUNT` × `REGION`), across 6 accounts. None
   reached the $50 floor; the largest was binbash-data-science (…4519) at $15.69. No pair can
   therefore cap S2.1 at `Unverified`. The queries ran in us-east-1, one account per call:
   - binbash-apps-devstg (…3444): EC2, ASG, EBS, RDS and Lambda came back empty; idle returned 2
     DynamoDB tables.
   - binbash-shared (…4258): EC2 returned 1 `OPTIMIZED`; ASG came back empty; EBS returned 1
     `Optimized`; Lambda returned 1 `NotOptimized` ($0 saving); idle returned 3 DynamoDB tables.
   - binbash-data-science (…4519): RDS returned 1 instance with `Optimized` sizing, flagged idle;
     Lambda came back empty; idle returned the same RDS instance.
   - binbash-apps-prd (…8489): RDS, Lambda and idle all came back empty.
   - binbash-security (…1242) and binbash-management (…7950, the payer): Lambda and idle came back
     empty.
   - binbash-network (…7662): idle came back empty.

   Every sizing call that came back empty was for a pair under the floor. The largest,
   binbash-apps-devstg (…3444), carried $5.83/mo of such spend. The three workshop accounts carried
   none and were not queried.
10. **S2.1 vs S2.2 overlap.** Both backlogs are the same six idle resources, so the two are never
    summed. Each DynamoDB table is priced differently by each source:
    - Compute Optimizer: $2.85/mo list, $1.93 after discounts.
    - Cost Optimization Hub: $1.63.

    S2.1 uses Compute Optimizer's list figure, $27.38 ($22.80 after discounts, which gives the same
    grade). S2.2 uses the Hub's, $21.27. Neither count includes:
    - a gp2→gp3 option ($0.32/mo) on an EBS volume whose finding is `Optimized`;
    - the Hub's 1 `MigrateToGraviton` recommendation ($1.03/mo);
    - the Hub's 454 `PurchaseReservedInstances` recommendations ($4.01/mo in all).

    The Hub items are neither idle nor right-sizing. Three of the five idle tables are
    `*-terraform-backend` state-lock tables, and one is tagged with a layer disabled in the IaC
    (`databases-dynamodb--`), so whoever acts on the backlog should confirm each table is unneeded
    before deleting it.
11. **S2.3 is $0.03 under the floor.** Commitment-eligible spend is **$49.97**:
    - Savings Plans coverage `TotalCost` $36.58: DynamoDB $20.31, SageMaker $10.45, EC2 $5.82,
      Lambda $0.00;
    - Reserved Instance coverage `OnDemandCost` for RDS $13.39 (744 on-demand hours, 0 reserved);
    - ElastiCache and OpenSearch: no August spend;
    - Redshift: not queried, since its entire August usage ($0.02) cannot lift the base to $50.

    RDS does not appear in Savings Plans coverage, so adding its Reserved Instance cost
    double-counts nothing. The coverage API now also counts SageMaker and DynamoDB (eligible for
    SageMaker and Database Savings Plans), beyond the skill's "EC2, Fargate, Lambda". Any growth in
    eligible spend makes S2.3 a graded signal, and at 0% coverage it would grade `Not met` (T4
    ≥60%, house opinion).
12. **Commitment ownership.** No commitments are owned, so T5 and T7 resolve to `N/A` through S2.3
    (S2.4, S5.3). The evidence:
    - `sp-explorer` returned no Savings Plans in any state.
    - `ri-performance` utilisation for August, grouped by `SUBSCRIPTION_ID`, returned no
      reservation (0 purchased hours).
    - The `RECORD_TYPE` mix has no `DiscountedUsage` or `RIFee`.
13. **S2.5.** Storage means S3 `TimedStorage` usage types only, S3 Vectors included: $0.456 of
    $54.84 S3 usage. Requests (`Requests-Tier1`/`Tier2`) are $54.35.
14. **Stage 3 bases.**
    - EC2 instance compute (`Amazon Elastic Compute Cloud - Compute`) $8.89: S3.1, S3.5.
    - AWS Lambda $0.00: S3.2, S3.3.
    - `NatGateway-Bytes` $0.07: S3.4. NAT hours ($2.43) are not data processing.

    Compute Optimizer still returned one `NotOptimized` Lambda function (a memory upsize with $0
    saving) and no Auto Scaling group. Neither grades anything while the stage is under the floor,
    and S3.4's directional-only caveat does not arise.
15. **S5.1 / S5.2.** The quiet-account carve-out did not trigger: 4 anomalies came back, all from one
    monitor. All four fall between 2026-09-14 and 2026-09-23, at most 11 days old at run time, so
    S5.2's `Not met` reflects a short triage window. Three of the four are Bedrock inference in
    binbash-data-science (…4519).
16. **S4.2 / S4.3.** There are no cost categories, so the `ProcessingStatus: APPLIED` caveat does not
    arise. `list-pricing-plans` returns two AWS-managed read-only plans (`BasicPricingPlan`,
    `Passthrough`), which are not evidence of showback.
17. **S4.1 access.** `list-account-associations` succeeded with this run's SSO Administrator
    credentials. A narrower FinOps read-only role may lack `billingconductor:ListAccountAssociations`.
    The skill then takes the accounts from Cost Explorer `LINKED_ACCOUNT` instead, which returned
    the same accounts here.
18. **What clearing Stage 1 would unlock.** This is a projection from this run's grades, not a
    grade. With S1.4 and S1.5 `Met`, Stage 2 (`Met`) and Stage 3 (all `N/A`) would carry the account
    to **Stage 3**, with S4.2 as the next gate. That holds only while S2.3 stays under the floor
    (note 11).
19. **Account identity.** Accounts are named `name (…NNNN)`. The prior block's `account` is
    `<MANAGEMENT_ACCOUNT_ID>`, which has no digits, so Phase 0 treated it as this payer, and the
    match is **assumed**.
20. **Phase 0.** The prior report is `finops-maturity-2026-09-23-1637.md` (`bb-finops-maturity/v1`),
    and its missing `n_a` counts are read as 0. Both runs use the same August baseline, so *Movement
    since 2026-09-23* isolates the change of method.
21. **Month-to-date run-rate** (usage basis, 2026-09-01..2026-09-25, end exclusive): $264.92 in 24
    days, $246.68 AWS-billed plus $18.24 Bedrock inference. That is about $11.04/day against
    August's $18.93/day, mostly because Claude Opus 5 inference fell from $206.44 in August to under
    $0.01. This is an emerging signal only.
22. **Cost of this run.** At most 16 Cost Explorer API requests, all single-page (≤ $0.16).

---

## Scorecard block

```yaml
schema: bb-finops-maturity/v2
generated: 2026-09-25
account: "…7950"   # never the full id
baseline_period: 2026-08-01..2026-09-01   # end exclusive
anomaly_window: 2026-06-27..2026-09-25
stage: 0                 # 0 = Stage 1 is not yet Met
gating_signal: S1.4
blocked_stage: null
stages:
  - id: 1
    name: visibility
    grade: partial
    signals: {met: 3, partial: 1, not_met: 1, unverified: 0, n_a: 0}
  - id: 2
    name: tactical
    grade: met
    signals: {met: 2, partial: 0, not_met: 0, unverified: 0, n_a: 3}
  - id: 3
    name: strategic
    grade: n_a
    signals: {met: 0, partial: 0, not_met: 0, unverified: 0, n_a: 5}
  - id: 4
    name: governance
    grade: partial
    signals: {met: 2, partial: 0, not_met: 2, unverified: 2, n_a: 0}
  - id: 5
    name: culture
    grade: partial
    signals: {met: 1, partial: 0, not_met: 1, unverified: 2, n_a: 1}
unverified: [S4.5, S4.6, S5.4, S5.5]
n_a: [S2.3, S2.4, S2.5, S3.1, S3.2, S3.3, S3.4, S3.5, S5.3]
```
