# Example — GCP SaaS → AWS migration ("Meridian")

> **Fictional walkthrough** of the `aws-startup-advisor` `migration-to-aws` skill. "Meridian"
> is an invented Series A B2B SaaS. No real account, data, or workload; all figures are
> illustrative estimates. This is documentation — there is no Terraform to apply here. When
> you run the skill for real it *generates* the Terraform; this page shows the *shape* of a
> run so you know what to expect and how to take it into the Leverage workflow.

See the [layer README](../README.md) for how to trigger the skill and the other use cases.

---

## The startup (Discover + Clarify inputs)

| Attribute | Value |
|---|---|
| Product | B2B SaaS — meeting scheduling + AI-generated meeting summaries |
| Stage | Series A, ~$3.2k/mo on GCP, 8 engineers (1 with infra experience) |
| Why move now | VC is a registered **AWS Activate Provider** → eligible for the **$100k** credits tier |
| HA needs | API + primary DB need HA; dev/staging can be single-AZ |
| Kubernetes | No preference → Fargate (skill does not default to EKS) |
| DB size | ~30 GB → `pgcopydb` for migration (DMS only recommended >500 GB) |
| AI feature | Meeting summaries via **OpenAI `gpt-4o`** → **Amazon Bedrock (Claude)** |

Meridian's existing GCP stack (what Discover reads): a Cloud Run API, a Cloud Functions
webhook handler, a regional Cloud SQL Postgres, Memorystore Redis, a GCS uploads bucket, a
Pub/Sub topic feeding a summary worker, Secret Manager, Cloud DNS, and an HTTPS load
balancer. The summary worker calls the OpenAI API (not a Terraform resource — detected from
app code).

---

## Service mapping (Design phase)

| GCP service (Terraform type) | AWS target | Confidence | Rationale |
|---|---|---|---|
| Cloud Run API (`google_cloud_run_v2_service`) | **ECS Fargate + ALB** | deterministic | Always-on (`min_instance_count=1`), cold-start sensitive → Fargate, not Lambda |
| Cloud Functions (`google_cloudfunctions2_function`) | **Lambda** | deterministic | Event-driven, 120s, Python 3.12 |
| Cloud SQL PostgreSQL REGIONAL (`google_sql_database_instance`) | **RDS Aurora PostgreSQL** (writer + reader) | deterministic | HA mirrors GCP REGIONAL; dev → Serverless v2 |
| Memorystore Redis STANDARD_HA (`google_redis_instance`) | **ElastiCache Redis** (multi-AZ) | deterministic | 1:1; auto-failover mirrors STANDARD_HA |
| Cloud Storage (`google_storage_bucket`) | **S3** | deterministic | Uploads + assets; versioning + public-access-block on |
| Pub/Sub (`google_pubsub_topic`) | **SNS + SQS** (+ DLQ) | inferred | Fan-out → SNS; durable worker queue → SQS |
| Secret Manager (`google_secret_manager_secret`) | **Secrets Manager** | deterministic | DB creds via Aurora `manage_master_user_password` |
| Cloud DNS (`google_dns_managed_zone`) | **Route 53** | deterministic | — |
| Cloud LB (`google_compute_forwarding_rule`) | **ALB** | inferred | L7 HTTP(S) |
| OpenAI `gpt-4o` (app code) | **Bedrock Claude (Sonnet family)** | inferred | Closest-fit; **not** 1:1 — re-validate before cutover |

> **Where BigQuery would land:** if Meridian used BigQuery the plugin would **not** auto-pick
> Athena/Redshift — it flags `Deferred — specialist engagement` and routes the team to their
> AWS account team / a data-analytics migration partner. Meridian has no warehouse, so this
> gate doesn't fire — called out because it's the plugin's most important "won't guess"
> behavior.

### Target architecture

```text
                          Route 53 (meridian.app)
                                   │
                                   ▼
                        ┌────────────────────┐
   Internet ─── 443 ──► │        ALB          │
                        └─────────┬──────────┘
                                  │  :8080
                    ┌─────────────▼──────────────┐   VPC 10.20.0.0/16
                    │  ECS Fargate — API service   │   2 AZs, private subnets
                    │  (Cloud Run → Fargate)       │
                    └───┬─────────┬─────────┬─────┘
                        │         │         │
              ┌─────────▼──┐ ┌────▼─────┐ ┌─▼──────────────┐
              │ Aurora PG   │ │ ElastiC. │ │ S3 (uploads)   │
              │ writer+read │ │ Redis HA │ └────────────────┘
              └─────────────┘ └──────────┘
                        ▲
   webhooks (Lambda) ───┘ (Cloud Functions → Lambda)
                                  SNS (summary-jobs)
                                   │  fan-out
                                   ▼
                                  SQS (worker) ──► DLQ
                                   │
                    ┌──────────────▼───────────────┐
                    │ Fargate summary worker         │
                    │  └─► Bedrock InvokeModel (IAM) │  (OpenAI → Bedrock)
                    └───────────────────────────────┘
```

---

## Cost estimate (Estimate phase)

> **Illustrative** us-east-1 on-demand estimate for the **prod** tier, credits **not**
> applied. Real numbers drift — the plugin pulls live pricing at run time, and on the actual
> Leverage layer you must re-run `make infracost-breakdown` before applying. Dev/staging is
> materially cheaper (single-AZ, Aurora Serverless v2, single NAT).

| Component | Sizing | Est. $/mo |
|---|---:|---:|
| ECS Fargate — API (2 tasks, 0.5 vCPU / 1 GB) | always-on ×2 | ~$35 |
| ECS Fargate — summary worker (1 task) | bursty | ~$18 |
| Lambda — webhooks | low volume | ~$2 |
| RDS Aurora PostgreSQL (2 × db.t4g.medium) | writer + reader | ~$120 |
| ElastiCache Redis (2 × cache.t4g.micro) | multi-AZ | ~$25 |
| ALB | 1 | ~$18 |
| NAT Gateway (single) | 1 | ~$33 |
| S3 + data transfer | ~50 GB | ~$5 |
| SNS + SQS | low volume | ~$1 |
| Route 53 | 1 zone | ~$1 |
| Bedrock (Claude) — summaries | usage-based | see note |
| **Infra subtotal (excl. Bedrock, excl. credits)** | | **~$258/mo** |

**Bedrock note:** summary token cost is usage-driven, not a fixed line item. At the `gpt-4o`
tier OpenAI can be ~29% cheaper per token, so the migration case is **provider consolidation
+ IAM auth (no third-party API key) + Activate credits**, not raw token price. Size it from
real transcript volume during the eval.

**Activate credits:** the **$100k** tier comfortably covers this footprint for the credit
term — the plugin surfaces this as the primary near-term cost lever.

---

## Phased cutover (what the Generate phase's guide covers)

1. **Prerequisites — account security first.** Enable root MFA, store root creds in a
   password manager, delete any root access keys; do day-to-day access via IAM Identity
   Center (the `management/global/sso` layer here — don't hand-roll IAM users). Tooling:
   `terraform`/`tofu`, `aws-cli`, `gcloud`, `docker`, `psql`, `pgcopydb`, and `boto3` for the
   AI track.
2. **Provision AWS infra** (VPC → Aurora/ElastiCache/S3 → Fargate/Lambda), no external
   traffic yet.
3. **Data migration.** Postgres (~30 GB) via **`pgcopydb`** — the skill picks the tool from
   DB size (`<10 GB` pg_dump; `10–500 GB` pgcopydb; `>500 GB` AWS DMS): full copy, then a
   short cutover-window delta. GCS → S3 via `gcloud storage rsync`. Redis is regenerable —
   just warm the cache.
4. **Application cutover.** Point app config at Aurora/ElastiCache endpoints; move secrets to
   Secrets Manager (DB creds via Aurora `manage_master_user_password`); repoint webhooks to
   Lambda; swap Pub/Sub publishes for SNS; workers consume from SQS (DLQ configured).
   Smoke-test against the ALB hostname before touching DNS.
5. **AI cutover (OpenAI → Bedrock)** — *compatibility-guided, not 1:1.* Enable Bedrock model
   access; replace the OpenAI SDK call with the Bedrock **Converse API** (the worker's task
   role gets `bedrock:InvokeModel` — **no API key**, IAM auth, so the `openai-api-key` secret
   is retired):

   ```python
   # before (OpenAI SDK)
   client.chat.completions.create(model="gpt-4o", messages=[...])

   # after (boto3 Bedrock Runtime — provider-agnostic message shape)
   bedrock.converse(modelId="us.anthropic.claude-sonnet-4-6", messages=[...])
   ```

   Run an eval harness on a golden set of transcripts (quality + latency vs `gpt-4o`), roll
   out behind a feature flag, ramp 5% → 50% → 100%.
6. **DNS cutover.** Lower TTLs 24–48h ahead; create Route 53 records pointing at the ALB;
   delegate the zone at the registrar. Watch error rates; keep GCP warm for rollback.
7. **Decommission GCP** only after a stable soak (≥1 week): scale Cloud Run to 0, disable
   Functions, snapshot then delete Cloud SQL, empty then delete GCS buckets, remove the
   OpenAI key.

---

## The important part — this is NOT a Leverage layer

Whatever the plugin generates is raw `hashicorp/aws` output. Turning it into a real
deployable layer means refactoring to repo conventions:

| Plugin output | Leverage convention |
|---|---|
| standalone `provider "aws"` + `default_tags` | `config.tf` provider + backend; `local.tags` (`Terraform`/`Environment`/`Layer`) |
| hardcoded region/name locals | `common-variables.tf` symlink + `config/*.tfvars` hierarchy |
| raw `hashicorp/aws` resources | **Binbash/Leverage modules** where one exists (VPC, RDS, etc.) |
| no state wiring | S3 backend + DynamoDB lock; remote-state data sources for cross-layer refs |
| no cost/CI wiring | add `infracost.yml` entry; add `atlantis.yaml` project if deployed |
| lives in a scratch dir | land in `apps-prd/us-east-1/<layer>` (or the right account/region) |

Then follow the normal flow: `leverage tofu init` → `plan` → **redacted plan to a PR** (see
repo [CLAUDE.md](../../../../CLAUDE.md#standard-workflow-posting-a-tofu-plan-to-a-pr-for-review))
→ human review → `leverage tofu apply`.
