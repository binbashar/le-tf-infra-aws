# AWS Startup Advisor — Reference Layer

> **Status: Documentation-only reference layer.** This directory intentionally
> contains **no `.tf` files** — it is prose, not infrastructure. The trailing
> space-plus-`--` suffix marks it as a disabled layer, so Atlantis autodiscover and
> `leverage tofu` never try to plan or apply it. It documents **how to use the
> [AWS Startup Advisor](https://aws.amazon.com/startups/) Claude Code plugin** inside
> this repository, across a few representative use cases.

---

## Why this layer exists

We enabled the official **`aws-startup-advisor@claude-plugins-official`** plugin in
[`.claude/settings.json`](../../../.claude/settings.json). It is Amazon's own Claude Code
plugin, built on patterns from AWS Startup Solutions Architects. It bundles five skills
that Claude auto-invokes when the conversation matches — no slash command required:

| Skill | What it does | Triggers on |
|---|---|---|
| **`architect-for-startups`** | Stage-appropriate AWS architecture advice (pre-revenue → Series B+), sized to runway, team, and credits. | "building on AWS", "which service", "prep architecture for fundraising" |
| **`migration-to-aws`** | 6-phase GCP → AWS migration (also OpenAI/Gemini → Bedrock). Discover → Clarify → Design → Estimate → Generate → Feedback. | "migrate from GCP", "GKE to EKS", "Cloud SQL to RDS", "OpenAI to Bedrock" |
| **`start-building-for-startups`** | Interactive discovery → writes an AWS scaffold directly into the project. | "build a new app", "scaffold a project on AWS" |
| **`knowledge-base-for-startups`** | AWS Activate FAQ, credits, programs, partner offers, sample architectures, learn articles. | "AWS Activate eligibility", "how many credits", "sample architecture for X" |
| **`prompt-library-for-startups`** | AWS-curated copy-paste prompts + installable agents (Bill Shock Preventer, Service Quota Agent, etc.). | "give me a prompt to do X on AWS", "installable cost-monitoring agent" |

These are **advisory / code-generation** capabilities. The plugin produces guidance,
Terraform, migration runbooks, and cost estimates — it does **not** touch AWS accounts or
state. Nothing here is wired into Atlantis, remote state, or SSO.

### How it fits the Leverage workflow

The plugin is a **design-time accelerator that feeds the normal Leverage layer
workflow** — it does not bypass it:

```text
  ┌─────────────────────────┐        ┌──────────────────────────────────────┐
  │  aws-startup-advisor      │        │  Leverage Reference Architecture       │
  │  (this plugin, advisory)  │        │  (how we actually ship)                │
  │  ───────────────────────  │        │  ────────────────────────────────────  │
  │  Advise / Design          │        │  1. Author {account}/{region}/{layer}  │
  │  Estimate cost            │  ────► │  2. leverage tofu plan → PR (redacted) │
  │  Generate raw .tf + docs  │  hand- │  3. Human review + approve             │
  │                           │   off  │  4. leverage tofu apply                │
  └─────────────────────────┘        └──────────────────────────────────────┘
```

Anything the plugin generates (raw Terraform, scaffolds) is a **starting point**, not
drop-in Leverage code. Before it becomes a real layer it must be refactored to repo
conventions — `config.tf` backend + providers, symlinked `common-variables.tf`,
`local.tags`, remote-state data sources, Leverage modules over raw resources, and
`infracost.yml` / `atlantis.yaml` wiring.

---

## How to use the plugin

The skills activate automatically from natural language — you do **not** type a slash
command. Open a Claude Code session at the repo root and describe the intent. The sections
below are the use cases we expect most often here; each shows the kind of prompt that
triggers the skill and what you get back.

### Use case 1 — Stage-appropriate architecture advice

**Skill:** `architect-for-startups`. Sizes recommendations to your stage, runway, team, and
credits rather than handing you the "ideal" (over-engineered) architecture.

```text
> We're Series A on a $3k/mo AWS budget with 8 engineers, one with infra experience.
> What should our compute layer look like?
```

It establishes context first (budget ceiling, # engineers touching infra, credits + expiry,
traffic, the one thing that kills the company if it breaks) and then recommends — e.g. for a
small team it leans to managed services (Fargate/Lambda/RDS) over self-managed EKS/EC2.

### Use case 2 — Migrating off GCP (the deep-dive example)

**Skill:** `migration-to-aws`. A gated 6-phase flow: **Discover → Clarify → Design →
Estimate → Generate → Feedback**. Point it at your existing GCP Terraform, app code, or a
billing export:

```text
> Migrate our GCP SaaS to AWS. Our Terraform is in ./infra, and the summary
> worker calls the OpenAI API.
```

- **Discover** reads `google_*` resources / app code / billing into a profile.
- **Clarify** asks picker questions for what artifacts can't answer (HA needs, Kubernetes
  preference, DB size → migration tooling, AI latency/quality targets). **Must finish before
  Design.**
- **Design** maps each GCP service to an AWS target with a confidence flag (`deterministic`
  for direct mappings, `inferred` for rubric-based).
- **Estimate** costs the target via the AWS Pricing MCP before writing any code.
- **Generate** writes raw Terraform + migration scripts + (if an AI track ran) a Bedrock
  adapter, plus a `MIGRATION_GUIDE.md`.

> **`.migration/` is plugin scratch.** Running the skill creates timestamped run dirs there.
> That path is disposable — git-ignore it; don't commit run output into a layer.

👉 A full walkthrough — fictional startup, GCP→AWS service mapping, target architecture,
cost framing, and phased cutover — is written up in
**[`examples/gcp-saas-migration.md`](./examples/gcp-saas-migration.md)**.

### Use case 3 — AWS Activate credits & programs

**Skill:** `knowledge-base-for-startups`. Answers factual questions about Activate
eligibility, credit tiers, accelerator/VC providers, and partner offers from bundled AWS
reference content.

```text
> Our lead VC is an AWS Activate Provider — which credit tier are we eligible for,
> and when do the credits expire?
```

For a company that qualifies through a registered provider, this is often the single biggest
near-term cost lever (e.g. the $100k tier covering a small production footprint for the
credit term). It won't look up your *account-specific* balance or membership status — that's
a console/support task.

### Use case 4 — Ready-made prompts & installable agents

**Skill:** `prompt-library-for-startups`. Surfaces AWS-curated copy-paste prompts (RAG
chatbot on Bedrock, security-baseline review, cost anomaly detection, GPU quota requests,
EKS deploy, Well-Architected review) and installable agents (Bill Shock Preventer, Service
Quota Agent, Multi-Account Transition Advisor).

```text
> Give me the AWS prompt for setting up cost anomaly detection.
```

Because you're already inside an AI coding agent, it offers to **run** the reference prompt
against your setup, **adapt** it, or hand it over to **copy** — rather than telling you to
paste it somewhere.

---

## Guardrails & caveats

- **Advisory only.** The plugin never authenticates to AWS/GCP or mutates state. Anything it
  generates is reviewed and refactored to Leverage conventions before it becomes a layer.
- **Dev sizing by default.** It defaults to development-tier capacity (e.g. `db.t4g.micro`,
  single-AZ, Aurora Serverless v2 min ACU) unless you specify production requirements.
- **AI migration is compatibility-guided, not parity.** OpenAI/Gemini → Bedrock model
  mappings are closest-fit; **re-test prompts, tool-calling, and eval metrics before
  cutover.** Do not treat the mapping as drop-in.
- **It won't guess on analytics.** For BigQuery (`google_bigquery_*`) the migration skill
  does **not** auto-pick Athena/Redshift — it flags `Deferred — specialist engagement` and
  routes you to your AWS account team / a data-analytics migration partner.
- **No human-time dollar estimates.** It costs infrastructure, not professional services or
  people-time.
- **Cost figures are estimates.** Pricing comes from the AWS Pricing MCP at run time and
  drifts; always re-run `make infracost-breakdown` on the real layer before applying.
- **Sensitive data.** Never paste real account IDs, keys, or customer data into the session.
  Examples in this layer are fictional. Follow the repo's
  [redaction workflow](../../../CLAUDE.md#standard-workflow-posting-a-tofu-plan-to-a-pr-for-review)
  when posting any plan output.

---

## References

- [AWS Startups](https://aws.amazon.com/startups/) · [AWS Activate](https://aws.amazon.com/activate/) · [Activate credits](https://aws.amazon.com/activate/credits/)
- [AWS Prescriptive Guidance — GCP to AWS](https://docs.aws.amazon.com/prescriptive-guidance/)
- [Amazon Bedrock](https://aws.amazon.com/bedrock/) · [AWS DMS](https://aws.amazon.com/dms/)
- Repo precedent for a documentation-only reference layer:
  [`security/us-east-1/security-monitoring-agent --`](../../../security/us-east-1/)
- Leverage: [directory structure](https://leverage.binbash.co/user-guide/ref-architecture-aws/dir-structure) · [modules](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile)
