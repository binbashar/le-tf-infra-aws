# Security Monitoring & the AWS Security Agent — Reference Layer

> **Status: Documentation-only reference layer.** This directory intentionally
> contains **no `.tf` files**. The trailing space-plus-`--` suffix marks it as a disabled
> layer, so Atlantis autodiscover and `leverage tofu` never try to plan or apply
> it. It exists to document a posture decision and to answer
> [issue #541 — *Review our implementation of the AWS security monitoring
> services*](https://github.com/binbashar/le-tf-infra-aws/issues/541).

This layer reviews our AWS **security monitoring** posture against the model in
[cloudonaut — *AWS Security Monitoring*](https://cloudonaut.io/2023-08-04-aws-security-monitoring/)
(referenced by the issue) and then updates that 2023-era recommendation with the
**AI security agents AWS has since shipped** — evaluating, for each, whether it
**complements** or **replaces** parts of the classic detective stack.

---

## TL;DR — the verdict

1. **The classic detective stack is the foundation and it is only half-on.**
   CloudTrail and IAM Access Analyzer are live; **AWS Config, Security Hub,
   GuardDuty, and Inspector are written but sitting in disabled `--`-suffixed layers.**
   The article's core recommendation (Config + Security Hub as the central pane,
   GuardDuty/Inspector feeding it) is therefore **not** currently realized in the
   `security` account. Re-enabling those layers is step one — see
   [Remediation checklist](#remediation-checklist).

2. **The "AWS Security Agent" is not one thing — it's three, on three different
   axes.** They do **not** replace the detective *sources* (you still must turn
   Config/GuardDuty/CloudTrail **on** to feed them). They replace the **human
   glue and aggregation layers** the 2023 article had to hand-roll, and they add
   a **build-time** axis that did not previously exist:

   | AWS AI offering | Axis | Verdict |
   |---|---|---|
   | **AWS Security Agent** (threat modeling, code review, on-demand pentest) | Build-time / shift-left | **Complementary** — new phase, no overlap |
   | **AI Investigative Agent** (in Security Incident Response) | Response-time / investigation | **Complementary** — replaces the manual **investigation** runbook (AWS-supported cases); not alert routing |
   | **Unified Security Hub** (exposure findings, attack-path correlation) | Aggregation evolution | **Replaces** our custom GuardDuty→Lambda→EventBridge routing |

   > **Bottom line:** keep the detectors, drop the bespoke glue. Re-enable the
   > foundation, then adopt **unified Security Hub + the Investigative Agent**
   > instead of rebuilding the custom Lambda/EventBridge alerting the article
   > describes, and add **AWS Security Agent** to cover pre-deployment.

---

## Background — the cloudonaut monitoring model

The article organizes AWS security telemetry into three layers. This is the lens
we use for the gap analysis below.

```text
   ┌──────────────────────────────────────────────────────────────────┐
   │  3. AGGREGATION      Security Hub  ── single pane, ASFF, scoring   │
   │        ▲                                                           │
   │        │  findings (deduplicated, correlated, prioritized)         │
   │  ──────┼───────────────────────────────────────────────────────   │
   │  2. ANALYSIS         Config Rules · GuardDuty · Inspector · Macie  │
   │        ▲                                                           │
   │        │  raw events                                               │
   │  ──────┼───────────────────────────────────────────────────────   │
   │  1. SOURCES          CloudTrail · VPC Flow Logs · Route 53 DNS ·   │
   │                      Config configuration items                    │
   └──────────────────────────────────────────────────────────────────┘
```

Article guidance we hold ourselves to:

- **AWS Config** enabled in every region in use, with ~**1-year** retention.
- **Security Hub** as the central pane, with the **AWS Foundational Security Best
  Practices (FSBP)** standard enabled across all regions.
- **GuardDuty** and **Inspector** as recommended analysis feeders.
- Findings routed by **severity/status** (the article filters severity ≥ 70,
  status = `NEW`) to avoid alert fatigue — either via a Lambda that sets findings
  to `NOTIFIED`, or a third-party tool.
- **Avoid duplicate findings**: Trusted Advisor, Config Rules, and Security Hub
  overlap — pick deliberately.

---

## Current posture in this repository

What the article recommends vs. **what is actually deployed today**. "Disabled"
means the layer exists and is written, but its directory carries the space-plus-`--` suffix
(or is an empty stub), so it is not applied.

| Service | cloudonaut stance | Where it lives in this repo | State | Gap |
|---|---|---|---|---|
| **CloudTrail** (org, multi-region, log validation, KMS) | Required source | `security/us-east-1/security-audit` (`terraform-aws-cloudtrail` `0.24.0`) | ✅ **Active** | none |
| **IAM Access Analyzer** | Recommended | `security/us-east-1/security-base` | ✅ **Active** | none |
| **AWS Config** (selected managed rules, 1-yr retention) | **Core / required** | `management/us-east-1/security-compliance` (active) · `security/us-east-1/security-compliance --` (**disabled**) (`terraform-aws-config` `v8.1.0`) | ⚠️ **Partial** | Enable + delegate to `security`; note this configures a **curated rule subset** (root-MFA, CloudTrail, GuardDuty, RDS/EC2 checks), **not** the full FSBP standard — that gap is closed by Security Hub |
| **Security Hub** (FSBP + CIS) | **Core / central pane** | `security/us-east-1/security-hub --` & `management/us-east-1/security-hub --` (**disabled**; `auto_enable_standards = "NONE"`) | ❌ **Disabled** | Delegate admin, enable standards org-wide |
| **GuardDuty** (all regions) | Recommended | `management/us-east-1/security-monitoring --` (**disabled**; `delegated-admin`) · `security/us-east-1/security-monitoring --` (**disabled**; `terraform-aws-guardduty-multiaccount` `v0.2.1` + custom `terraform-aws-guardduty-monitor` `v1.2.1`) | ❌ **Disabled** | Delegate admin from management, then re-enable in security |
| **Amazon Inspector** (EC2/ECR) | Recommended | `management/us-east-1/security-compliance` (delegation, gated on `enable_inspector`) · `security/us-east-1/security-compliance --` (**disabled**; `inspector2` via `null_resource`) | ❌ **Disabled** | Set `enable_inspector = true` in management, then enable in security |
| **Amazon Macie** | Mentioned | — | ❌ **Absent** | Net-new (optional; sensitive-data discovery) |
| **Amazon Detective** | Mentioned | — | ❌ **Absent** | Net-new (optional; investigation graphs) |

> **Note on the active `security-monitoring/` directory:** the non-suffixed
> `security/us-east-1/security-monitoring/` is currently an **empty stub** (only a
> stale `.infracost/` cache, no `.tf`). The real GuardDuty code is in the disabled
> `security-monitoring --` sibling. Re-activation means promoting that code, not
> writing it from scratch.

**Reading of the gap:** the *sources* layer is **partially** covered — CloudTrail
(org-wide) and Config-in-management are confirmed active, but the other sources the
diagram lists are **not verified enabled for the `security` account**: VPC Flow
Logs exist only in the `base-network` layers of other accounts (`shared`,
`apps-prd`, `apps-devstg`), and **Route 53 DNS query logging is absent repo-wide**.
The **analysis** and **aggregation** layers the article calls "core" are switched
off in the `security` account. The good news: most of the code already exists — so
the bulk of this is a **re-enablement and delegation** exercise, with VPC
Flow/DNS-logging coverage to confirm (or add) separately.

---

## The AWS Security Agent landscape (2025+)

When the issue says *"the latest AWS Security Agent that most probably can be
complementary or even replace this possible solution,"* the important discovery
is that **three distinct agentic offerings** now exist, each on a different axis of
the security lifecycle. Conflating them leads to the wrong conclusion, so we treat
them separately.

### A. AWS Security Agent — *build-time / shift-left*

A frontier agent that secures applications **before deployment**. Security teams
define organizational requirements once in the console (approved auth libraries,
logging standards, data-access policies); the agent then enforces them across
teams. Capabilities:

- **Design security review** — real-time feedback on architecture/design docs
  against your standards, before any code is written.
- **Threat modeling** — generates a system overview (components, trust
  boundaries, data flows) and a **STRIDE**-classified threat list (Spoofing,
  Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege)
  with severities and recommendations; re-runnable as code evolves.
- **Code security review** — full-repo scans from GitHub / GitLab / Bitbucket /
  GitHub Enterprise / S3, plus automated **pull-request analysis** posting
  findings (and fix PRs) inline.
- **On-demand penetration testing** — deploys specialized agents that build deep
  application understanding and execute multi-step attack chains, documenting
  reproducible attack paths and generating fix PRs.

**Verdict: Complementary — a new axis.** The detective stack (Config/GuardDuty/
Security Hub) only observes **running** infrastructure. Nothing in our current
posture addresses design-time or code-time risk. AWS Security Agent fills a phase
the cloudonaut model never covered; there is **no overlap** to replace.
Docs: <https://docs.aws.amazon.com/securityagent/latest/userguide/what-is.html>

### B. AI Investigative Agent (AWS Security Incident Response) — *response-time*

An AI agent embedded in **AWS Security Incident Response** that activates
automatically when an AWS-supported case is opened and runs **in parallel** with
AWS responders:

- **Automated evidence gathering** — queries **CloudTrail, IAM, EC2, and Cost
  Explorer** without manual log analysis.
- **Analysis & correlation** — correlates evidence across services, builds an
  event timeline.
- **Investigation summary in minutes** — findings, timeline, and recommendations
  posted to the case Investigation tab and Communication section.
- **Auditable & private** — acts via the `AWSServiceRoleForSupport`
  service-linked role (read-only); actions logged in CloudTrail; customer data is
  **not** used for training.

Enablement is org-level (AWS Organizations management account); AI investigation
applies to **AWS-supported** cases (not self-managed).

**Verdict: Complementary — replaces manual *investigation*, not alert routing.**
It **consumes the same CloudTrail** our `security-audit` layer already produces —
reinforcing that the source layer must stay on. It does **not** replace the
detectors, and it does **not** handle severity-filtering/notification routing
(that's finding C, unified Security Hub) — it answers *"what happened here?"* by
**replacing the manual investigation runbook** for a case, the step after a
finding is escalated. Scope limits to keep in mind: it applies to **AWS-supported
cases only** (not self-managed), is oriented to **threat-detection**
investigations rather than posture/compliance findings, and is invoked per-case
rather than as a standing notification path.
Docs: <https://docs.aws.amazon.com/security-ir/latest/userguide/ai-investigative-agent.html>

### C. Unified Security Hub — *aggregation-layer evolution*

The aggregation layer itself has evolved. Alongside the classic **Security Hub
CSPM** (posture management — FSBP/CIS/PCI/NIST control checks and security
scores), AWS now offers **exposure findings**: signals from **Security Hub CSPM,
GuardDuty, Inspector, and Macie** are **correlated** into prioritized exposures,
with **potential attack-path graphs** and severity based on exploit likelihood +
impact — surfaced on a new summary dashboard.

**Verdict: Replaces our custom glue.** Our disabled GuardDuty layer ships a custom
**`terraform-aws-guardduty-monitor`** Lambda that reacts to findings and routes
alerts — exactly the hand-rolled "severity ≥ 70 → notify" logic the article
describes. Native **exposure-finding correlation** subsumes most of that: instead
of writing Lambda to dedupe and prioritize across GuardDuty/Inspector/Macie, the
service does it and draws the attack path. Keep the **detectors**; retire the
**custom correlation/notification code** in favor of native Security Hub +
EventBridge automation rules.
Docs: <https://docs.aws.amazon.com/securityhub/latest/userguide/exposure-findings.html>
· <https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html>

---

## Target reference architecture

Detective foundation (re-enabled) feeding a native aggregation/correlation layer,
wrapped by the two agents at the ends of the lifecycle.

```text
   BUILD-TIME                     RUN-TIME (detect → aggregate)                 RESPONSE-TIME
   ─────────                      ─────────────────────────────                ─────────────

  ┌───────────────────┐        ┌──────────────────────────────────────┐     ┌────────────────────┐
  │ AWS Security Agent │        │ SOURCES                              │     │ AI Investigative   │
  │  · design review   │        │  CloudTrail (org) ✅  · Config ⚠️     │     │ Agent (Security    │
  │  · threat model    │        │  VPC Flow · Route 53 DNS             │     │ Incident Response) │
  │    (STRIDE)        │        │            │                         │     │                    │
  │  · code review     │        │            ▼                         │     │  reads CloudTrail, │
  │  · on-demand pentest│       │ ANALYSIS                             │     │  IAM, EC2, Cost    │
  └─────────┬─────────┘        │  GuardDuty ❌ · Inspector ❌          │     │  Explorer → builds │
            │                   │  Macie (opt) · Config Rules          │     │  timeline + summary│
            │ fix PRs           │            │                         │     └─────────▲──────────┘
            ▼                   │            ▼                         │               │
   ┌──────────────────┐        │ AGGREGATION — Unified Security Hub    │     case ─────┘
   │  Git repos /      │        │  · FSBP + CIS controls (CSPM)        │
   │  CI-CD pipeline   │        │  · exposure findings (correlation)   │────► EventBridge
   └──────────────────┘        │  · attack-path graphs                │      automation rules
                                │  delegated-admin: security account   │      / notifications
                                └──────────────────────────────────────┘
   ✅ active today   ⚠️ partial (management only)   ❌ written but disabled (-- suffix)
```

### Phased adoption path

| Phase | Goal | Actions |
|---|---|---|
| **1 — Restore the foundation** | Turn the article's "core" back on | Re-enable Config + Security Hub + GuardDuty + Inspector layers (see checklist); delegate admin to the `security` account |
| **2 — Modernize aggregation** | Replace custom glue with native | Enable **unified Security Hub** exposure findings; migrate the `guardduty_monitor` Lambda logic to **EventBridge automation rules**; retire the custom module |
| **3 — Add response-time AI** | Cut investigation from days to hours | Enable **AWS Security Incident Response** from the Organizations **management account**; onboard the **membership** (select OUs/accounts for coverage), confirm the service is available in the **regions** in use, configure **incident-response contacts** and permissions, then verify the **Investigative Agent** activates on AWS-supported cases |
| **4 — Add build-time AI** | Shift security left | Onboard **AWS Security Agent**; wire code review to repos and add threat modeling to the design workflow |

---

## Remediation checklist

The detective layers already exist — this is **re-enablement + delegation**, not
new code. Order matters: delegate from `management`, then enable in `security`.

- [ ] **AWS Config** — apply `management/us-east-1/security-compliance` (delegation),
      then rename `security/us-east-1/security-compliance --` → drop the
      space-plus-`--` suffix and apply in the `security` account. Confirm ~1-year
      retention per region in use.
- [ ] **Security Hub** — apply `management/us-east-1/security-hub --` (delegate
      admin), then enable `security/us-east-1/security-hub --`; flip
      `auto_enable_standards` from `NONE` and confirm **FSBP + CIS** are active
      org-wide.
- [ ] **GuardDuty** — apply `management/us-east-1/security-monitoring --` first
      (the `delegated-admin` module designates the `security` account as GuardDuty
      delegated administrator), then enable `security/us-east-1/security-monitoring --`
      (multi-account setup); promote it over the empty active `security-monitoring/`
      stub. **Defer/skip** the custom `terraform-aws-guardduty-monitor` Lambda —
      prefer native exposure findings + EventBridge (Phase 2).
- [ ] **Inspector** — set `enable_inspector = true` and apply
      `management/us-east-1/security-compliance` first (its
      `awsinspector_delegation.tf` runs `inspector2 enable-delegated-admin-account`
      for the `security` account, gated on that variable), then enable
      `security/us-east-1/security-compliance --`; confirm EC2 + ECR coverage across
      members.
- [ ] **Macie / Detective** *(optional)* — evaluate net-new for sensitive-data
      discovery and investigation graphs.
- [ ] **Aggregation cleanup** — once exposure findings are on, migrate alert
      routing to EventBridge automation rules and **retire** the custom Lambda.
- [ ] **Response-time** — enable **AWS Security Incident Response** from the
      management account; onboard membership (OU/account coverage), confirm
      supported regions, and set incident-response contacts so the Investigative
      Agent activates on AWS-supported cases.
- [ ] **Build-time** — onboard **AWS Security Agent**; connect repos + design flow.

> Follow the repo standard workflow for every layer you re-enable: generate a
> `leverage tofu plan`, **redact** account IDs/ARNs, attach the redacted excerpt to
> the PR in a `<details>` block, and **let a human apply after approval** — never
> apply from automation. See the root `CLAUDE.md` for the exact redaction procedure.

---

## Cost & tagging notes

- These are mostly **usage-priced** services (Config per configuration item +
  rule evaluation; GuardDuty per event/GB analyzed; Inspector per instance/image;
  Security Hub per check/finding-ingestion). Re-enabling them org-wide has a real
  monthly cost — run `make infracost-breakdown` on each layer before applying, and
  scope regions to those actually in use (the article's advice, and a cost lever).
- **Do not** add the `aws-apn-id` PRM tag to these layers. That tag is scoped to
  specific Bedrock/Marketplace layers under `data-science/` and requires Partner
  Development Manager approval (see root `CLAUDE.md`). Security monitoring layers
  are out of scope for Marketplace attribution.

---

## References

- Issue #541 — <https://github.com/binbashar/le-tf-infra-aws/issues/541>
- cloudonaut, *AWS Security Monitoring* — <https://cloudonaut.io/2023-08-04-aws-security-monitoring/>
- AWS Security Agent (build-time) — <https://docs.aws.amazon.com/securityagent/latest/userguide/what-is.html>
- AI Investigative Agent (Security Incident Response) — <https://docs.aws.amazon.com/security-ir/latest/userguide/ai-investigative-agent.html>
- Security Hub CSPM — <https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html>
- Security Hub exposure findings — <https://docs.aws.amazon.com/securityhub/latest/userguide/exposure-findings.html>
- Related detective layers in this repo:
  - **security account:** `security/us-east-1/security-audit` (CloudTrail) · `security/us-east-1/security-base` (Access Analyzer) · `security/us-east-1/security-compliance --` (Config + Inspector) · `security/us-east-1/security-hub --` · `security/us-east-1/security-monitoring --` (GuardDuty)
  - **management account (delegation):** `management/us-east-1/security-compliance` (Config + Inspector delegation) · `management/us-east-1/security-hub --` · `management/us-east-1/security-monitoring --` (GuardDuty delegated-admin)
