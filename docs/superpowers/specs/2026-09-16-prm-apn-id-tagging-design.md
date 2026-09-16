# PRM `aws-apn-id` tagging across the reference architecture

- **Date:** 2026-09-16
- **Context:** AWS Partner Revenue Measurement (PRM) compliance, required to retain AI Competency
  Signature Benefits (MDF, AI Production Ready funding, GTM resources). Raised by the Partner
  Development team; tracked internally in the PRM Compliance tracker (Confluence, BDPS space).
- **Precedent:** [#1071](https://github.com/binbashar/le-tf-infra-aws/pull/1071) — added the tag to
  three `data-science` Bedrock layers.
- **Status:** approved for planning

## Problem

PRM attributes AWS consumption to an AWS Marketplace listing via the cost allocation tag
`aws-apn-id = pc:<marketplace-product-code>`. Today only **3 of 163** layers in this repo carry it
(the Bedrock layers from #1071). Everything else — EKS, RDS, VPC/Transit Gateway, CloudFront, S3,
ECS, Lambda — drives AWS consumption that is **not attributed to binbash**, so it does not count
toward partner performance or funding eligibility.

CLAUDE.md currently forbids widening the tag ("Do NOT add this tag to other layers without explicit
Partner Development Manager approval"). That approval has now been given, and the policy inverts:
the tag becomes the default across the ref arch.

## Findings that shape the design

### 1. Product codes are retrievable from the CLI, not just the console

The onboarding guide says to read the code out of the Marketplace Management Portal UI. It is also
in the Catalog API, which makes it scriptable and reviewable:

```bash
aws marketplace-catalog describe-entity --catalog AWSMarketplace --entity-id prod-xxxxxxxxxxxxx \
  --query 'DetailsDocument.Description.ProductCode' --output text
```

Requires only the management (seller) account profile. Verified against the known-good pair:
`prod-zw4ehbg5ayh2m` → `b6t445987ttlzwgcll8zdt8nv`, matching the value already in the tree.

### 2. The originally proposed horizontal listing is de-listed

The listing first proposed for the non-AI layers — *Leverage AWS Well-Architected Review and
Implementation* (`prod-d4amcyizh5rey`, `pc:ek0yahiasjn4h1k7jb85ojx0y`) — reports
`Visibility: Restricted` in the catalog, and its public product page no longer renders a product.
Seven listings flipped to `Restricted` on 2026-09-02/03: *Well-Architected Framework Review*,
*Security Baseline*, *ISOGuard*, *Leverage AWS WA Review & Implementation*, *Cost Monitoring,
Optimization & Reports*, *Well-Architected Landing Zone*, *Leverage | AWS GenAI LLM RAG PoC-Chatbot*.

AWS's compliance checklist requires *at least one **public** Marketplace product listing*, so the
horizontal code was moved to a Public, Active listing instead.

### 3. The AI code was already correct

The listing proposed for "Data & AI" resolves to *GenAI Assessment for Startups | AI/ML Readiness &
Roadmap* (`prod-zw4ehbg5ayh2m`) — the same product code already applied by #1071. No change needed
on the AI side; it only needed confirming.

### 4. PRM now covers 90 services, not 4

The AI-specific restriction (SageMaker / Bedrock / AgentCore / Comprehend) was lifted. The
authoritative list is the *Resource Tagging Included Services* CSV in the PRM onboarding guide.
Notably **out of scope**: IAM, Organizations, Identity Center, GuardDuty, Config, CloudTrail,
Inspector and Macie — which is most of `base-identities`, `sso`, `organizations` and `security-base`.

### 5. The disabled-layer suffix has two forms

CLAUDE.md documents disabled layers as ending in a space followed by `--`. In practice **11 of the
67** disabled directories use the attached form (`databases-dynamodb--`, `bedrock-agent--`), and one
carries a trailing space (`airflow-- `). `@bin/scripts/version_support/discover.py` already handles
all three via `segment.rstrip().endswith("--")`; only the CLAUDE.md prose is incomplete. Counting
layers with the documented rule alone misclassifies 11 dormant layers as active, so any tooling added
here must reuse the `discover.py` rule rather than matching `" --"`.

### 6. PRM scope cannot be decided by static analysis

Scanning layers for PRM-billable services produces false negatives: `base-tf-backend` creates S3 and
DynamoDB (both billable) but scans clean, because its module is named `tfstate-backend`. AWS's own
guidance points the same way:

> Partner Revenue Measurement intends to support all AWS services. We recommend that you instrument
> PRM on all AWS services and resources that your partner solution interacts with to avoid on-going
> operational changes as service coverage expands.

A tag on a non-billable resource is simply ignored. Blanket tagging is therefore both cheaper to
maintain and better aligned with AWS guidance than a curated subset.

## Decisions

| Decision | Choice |
|---|---|
| Horizontal (non-AI) product | *Leverage \| AWS Modernization (Containers / Serverless)* — Public, Active |
| AI product | *GenAI Assessment for Startups* — Public, Active (unchanged from #1071) |
| Scope | All **98 active** layers, plus the **65 disabled** (`--`) layers for consistency |
| Split rule | By account, not by layer semantics |
| Mechanism | Central derived local + one line per layer's `local.tags` |

Rejected alternatives:

- **Literal `pc:` string per layer** (the #1071 pattern repeated 163×) — no single source of truth;
  a product-code change means editing every layer again, with no way to catch a straggler.
- **Provider `default_tags` everywhere** — strongest coverage, but touches provider blocks pinned
  anywhere from `aws ~> 3.0` to `~> 6.0`, where `default_tags` has known `tags`/`tags_all`
  perpetual-diff behaviour on older majors. The 19 layers that already wire `default_tags` pick the
  new tag up for free under the chosen approach, so its benefit is retained where already proven safe.
- **Per-layer semantic split** (only Bedrock/SageMaker layers get the AI code) — more literally
  accurate per resource, but makes every new layer a judgment call that will rot.
- **Three-bucket split** (separate DataLake / LakeHouse codes) — higher attribution fidelity and the
  eventual goal, but three codes to keep aligned with ACE opportunity tagging. Deferred.

## Design

### Central definition

`config/common-variables.tf` is symlinked into every layer and already derives `current_region` and
`layer_name`. Its `locals` block gains the product-code map. The account key needs no path parsing:
`var.environment` equals the account directory name in all seven `{account}/config/account.tfvars`.

```hcl
  # PRM -- AWS Partner Revenue Measurement attribution.
  # Tag `aws-apn-id = pc:<marketplace-product-code>` maps AWS consumption to a
  # Marketplace listing. Keyed by account: var.environment == account name in
  # every {account}/config/account.tfvars.
  prm_product_codes = {
    default        = "pc:5k5o9j3cjaqzpbiwt7ww6e65o" # Leverage | AWS Modernization (Containers / Serverless) -- prod-pkadanxklqjdc
    "data-science" = "pc:b6t445987ttlzwgcll8zdt8nv" # GenAI Assessment for Startups | AI/ML Readiness & Roadmap -- prod-zw4ehbg5ayh2m
  }
  prm_apn_id = lookup(local.prm_product_codes, var.environment, local.prm_product_codes["default"])
```

Adding an account is one map entry; changing a product code is one line.

### Per-layer wiring

```hcl
locals {
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
  }
}
```

Coverage breakdown:

| Group | Count | Work |
|---|---|---|
| Active, has a `local.tags` map | 80 | scripted one-line insert |
| Active, no tags map | 18 | manual — inspect what the layer passes to its modules first |
| Disabled, has a `local.tags` map | 45 | scripted one-line insert |
| Disabled, no tags map | 20 | manual, same as above |
| Already wire `default_tags { tags = local.tags }` | 19 | inherit automatically, no extra change |

For the 38 layers with no tags map, adding a `local.tags` that nothing consumes achieves nothing.
Each needs its module/resource `tags` arguments inspected and wired, or an explicit note in the PR
saying why the layer is genuinely untaggable (e.g. it creates only IAM and Organizations resources).

### Cost allocation tag activation

`management/global/cost-mgmt` pins `aws = 5.100.0` and already manages `aws_ce_anomaly_monitor`, so
activation belongs there:

```hcl
resource "aws_ce_cost_allocation_tag" "prm_apn_id" {
  tag_key = "aws-apn-id"
  status  = "Active"
}
```

Without this the tag is applied but **Inactive**: it never reaches Cost Explorer or the CUR, so
there is no way to verify attribution landed. This is the same failure already observed org-wide,
where the overwhelming majority of spend reads as untagged despite tags being present on resources.

### Guardrail

A `make` target plus a pre-commit hook asserting that every active layer's `local.tags` contains
`aws-apn-id`, mirroring the existing `make version-support` guardrail. Layers legitimately without a
tags map are listed in an explicit allowlist so the check stays green and the exceptions stay visible.

### Documentation

- Rewrite the CLAUDE.md PRM bullet: the prohibition becomes the default, with the account→code map
  and the CLI retrieval command.
- Record that Marketplace listing visibility matters — a `Restricted` listing should not be used as
  a tagging target.

## Verification

This is a tag-only change, so the plan signature is narrow and easy to police:

- Every diff must be an in-place update touching only `tags` / `tags_all`.
- **A single resource replacement in any plan means stop.** Some resources force replacement on tag
  changes; those must be found at plan time, not apply time.
- 163 layers cannot all be planned by hand. Plan a representative sample — one layer per account,
  plus the highest-risk resource types (EKS, RDS, CloudFront) — and post redacted output following
  the plan-redaction procedure in CLAUDE.md.
- `leverage tofu format` and `leverage tofu validate` before pushing; `make pre-commit` must pass.

## Out of scope / follow-ups

- **Bedrock model-invocation spend.** Resource tagging attributes infrastructure only. Bedrock model
  invocations attribute solely through a tagged **Application Inference Profile**, and only for
  Amazon/OSS models — Anthropic Claude invocations require the User-Agent String method instead. The
  Bedrock layers' model spend therefore remains unattributed after this change. Tracked as a separate
  issue.
- **Three-bucket product mapping** (DataLake / LakeHouse codes for data layers).
- **Client accounts.** This spec covers binbash's own accounts. Propagating the tag to client
  engagements is a separate effort, best served by making this repo the reference.
- **ACE opportunity tagging**, which must stay aligned with whichever product codes are used here.

## Risks

| Risk | Mitigation |
|---|---|
| A resource forces replacement on tag change | Plan review before apply; stop on any replacement |
| `local.tags` exists but is not propagated to a layer's modules | Plan output is the real check — a layer whose plan shows no tag change is not actually wired |
| Product code changes later | Single map entry in `config/common-variables.tf` |
| A new layer forgets the tag | Guardrail check + allowlist |
| Tag applied but never activated for cost allocation | `aws_ce_cost_allocation_tag` in `management/global/cost-mgmt` |
