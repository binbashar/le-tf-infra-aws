# AWS Startup Advisor — Reference Layer

> **Status: Documentation-only reference layer.** This directory intentionally
> contains **no deployable `.tf` files**. The trailing space-plus-`--` suffix marks it
> as a disabled layer, so Atlantis autodiscover and `leverage tofu` never try to
> plan or apply it. The worked-example infrastructure under
> [`examples/gcp-saas-migration/`](./examples/gcp-saas-migration/) uses the
> `.tf.example` extension so it is never parsed as a real layer either. It exists to
> document **how to use the [AWS Startup Advisor](https://aws.amazon.com/startups/)
> Claude Code plugin** inside this repository, with a fully worked
> **GCP-SaaS → AWS migration** as the running example.

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

These are **advisory / code-generation** capabilities. The plugin produces Terraform,
migration runbooks, and cost estimates — it does **not** touch AWS accounts or state.
Nothing here is wired into Atlantis, remote state, or SSO.

### How it fits the Leverage workflow

The plugin is a **design-time accelerator that feeds the normal Leverage layer
workflow** — it does not bypass it:

```text
  ┌─────────────────────────┐        ┌──────────────────────────────────────┐
  │  aws-startup-advisor      │        │  Leverage Reference Architecture       │
  │  (this plugin, advisory)  │        │  (how we actually ship)                │
  │  ───────────────────────  │        │  ────────────────────────────────────  │
  │  Discover GCP Terraform   │        │  1. Author {account}/{region}/{layer}  │
  │  Design AWS target        │  ────► │  2. leverage tofu plan → PR (redacted) │
  │  Estimate cost            │  hand- │  3. Human review + approve             │
  │  Generate raw .tf + docs  │   off  │  4. leverage tofu apply                │
  └─────────────────────────┘        └──────────────────────────────────────┘
```

The plugin's raw Terraform is a **starting point**, not drop-in Leverage code. Before it
becomes a real layer it must be refactored to repo conventions — `config.tf` backend +
providers, symlinked `common-variables.tf`, `local.tags`, remote-state data sources,
Leverage modules over raw resources, and `infracost.yml` / `atlantis.yaml` wiring. The
[migration guide](./examples/gcp-saas-migration/MIGRATION_GUIDE.md) calls out exactly
where that refactor happens.

---

## How to use the plugin

The skills activate automatically from natural language. You do **not** type a slash
command. Just describe the intent in a Claude Code session opened at the repo root:

```text
# Architecture advice (architect-for-startups)
> We're Series A on a $3k/mo AWS budget with 8 engineers, one with infra experience.
> What should our compute layer look like?

# Migration (migration-to-aws) — the running example in this layer
> Migrate our GCP SaaS to AWS. Here's our Terraform: examples/gcp-saas-migration/source-gcp/

# Activate credits / programs (knowledge-base-for-startups)
> Are we eligible for AWS Activate credits, and how much?

# A ready-made prompt or installable agent (prompt-library-for-startups)
> Give me the AWS prompt for setting up cost anomaly detection.
```

### The `migration-to-aws` 6-phase flow

The migration skill is gated — each phase must complete before the next:

1. **Discover** — reads GCP resources from Terraform (`google_*`), app code, and/or billing
   exports. Writes a discovery profile under a run dir (`.migration/<mmdd-hhmm>/`).
2. **Clarify** — asks picker questions for anything the artifacts can't answer (HA needs,
   Kubernetes preference, DB size for tooling choice, AI latency/quality targets). **Must
   finish before Design.**
3. **Design** — maps each GCP service to its AWS target (see mapping table below), records
   confidence (`deterministic` for direct mappings, `inferred` for rubric-based).
4. **Estimate** — costs the target architecture via the AWS Pricing MCP before any code.
5. **Generate** — writes raw Terraform, migration scripts, an AI adapter (if an AI track
   ran), plus `MIGRATION_GUIDE.md` and `README.md`.
6. **Feedback** — optional.

> **Note — `.migration/` is a plugin scratch directory.** When you actually run the skill it
> creates timestamped run dirs there. That path is disposable and should be git-ignored, not
> committed. The curated, reviewed output lives under `examples/` in this layer instead.

---

## Worked example — Meridian (GCP SaaS → AWS)

[`examples/gcp-saas-migration/`](./examples/gcp-saas-migration/) is a **complete, curated
run** of `migration-to-aws` for a fictional startup. See its
[README](./examples/gcp-saas-migration/README.md) for the full service mapping, target
architecture diagram, and cost estimate, and the
[MIGRATION_GUIDE](./examples/gcp-saas-migration/MIGRATION_GUIDE.md) for the phased cutover.

**Meridian** (assumptions — fictional):

- **Product:** B2B SaaS — meeting scheduling with AI-generated meeting summaries.
- **Stage:** Series A, 8 engineers (1 with infra experience), ~$3.2k/mo on GCP.
- **AWS Activate:** eligible for the **$100k** credits tier via their VC (a registered
  Activate Provider) — a core reason the plugin recommends AWS now.
- **AI feature:** meeting summaries currently call the **OpenAI** API → migrated to
  **Amazon Bedrock (Claude)**.

### GCP → AWS service mapping (as the plugin resolves it)

| GCP service (Terraform type) | AWS target | Confidence | Notes |
|---|---|---|---|
| Cloud Run — API (`google_cloud_run_v2_service`) | **ECS Fargate** | deterministic | Always-on HTTP, container-native → Fargate over Lambda |
| Cloud Functions — webhooks (`google_cloudfunctions2_function`) | **Lambda** | deterministic | Event-driven, <15 min, Python |
| Cloud SQL PostgreSQL (`google_sql_database_instance`) | **RDS Aurora PostgreSQL** | deterministic | Serverless v2 for dev/staging; provisioned for prod |
| Memorystore Redis (`google_redis_instance`) | **ElastiCache Redis** | deterministic | 1:1 mapping |
| Cloud Storage (`google_storage_bucket`) | **S3** | deterministic | Uploads + static assets |
| Pub/Sub (`google_pubsub_topic`) | **SNS + SQS** | inferred | Fan-out topic → SNS; worker queue → SQS |
| Secret Manager (`google_secret_manager_secret`) | **Secrets Manager** | deterministic | App secrets, DB creds |
| Cloud DNS (`google_dns_managed_zone`) | **Route 53** | deterministic | — |
| Cloud Load Balancing (`google_compute_forwarding_rule`) | **ALB** | inferred | HTTP(S) L7 |
| OpenAI API (in app code) | **Amazon Bedrock (Claude)** | inferred | Compatibility-guided, **not** 1:1 — re-validate prompts + evals before cutover |

> **Where BigQuery would land:** if Meridian used BigQuery, the plugin would **not**
> auto-pick Athena/Redshift. It flags `Deferred — specialist engagement` and routes the
> team to their AWS account team / a data-analytics migration partner. Meridian has no
> warehouse, so this gate does not fire — noted here because it's the plugin's most
> important "won't guess" behavior.

---

## Guardrails & caveats

- **Advisory only.** The plugin never authenticates to AWS/GCP or mutates state. Generated
  Terraform is reviewed and refactored to Leverage conventions before it becomes a layer.
- **Dev sizing by default.** The skill defaults to development-tier capacity
  (e.g. `db.t4g.micro`, single-AZ, Aurora Serverless v2 min ACU) unless you specify
  production requirements. Meridian's prod tier is called out explicitly in the example.
- **AI migration is compatibility-guided, not parity.** OpenAI/Gemini → Bedrock model
  mappings are closest-fit; **re-test prompts, tool-calling, and eval metrics before
  cutover.** Do not treat the mapping as drop-in.
- **No human-time dollar estimates.** The plugin costs infrastructure, not professional
  services or people-time.
- **Cost figures are estimates.** Pricing comes from the AWS Pricing MCP at run time and
  drifts; always re-run `make infracost-breakdown` on the real layer before applying.
- **Sensitive data.** Never paste real account IDs, keys, or customer data into the
  session. The example here is entirely fictional. Follow the repo's
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
