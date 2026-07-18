# Meridian — GCP SaaS → AWS migration (worked example)

> **Fictional.** "Meridian" is an invented Series A B2B SaaS used to demonstrate the
> `aws-startup-advisor` plugin's `migration-to-aws` skill end-to-end. No real account,
> data, or workload. All figures are illustrative estimates.

This is a curated capture of what the plugin's 6-phase migration flow produces, so a
reader can see the whole shape without running it. The parent
[README](../../README.md) explains how to trigger the skill yourself.

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

Source Terraform the Discover phase reads:
[`source-gcp/main.tf.example`](./source-gcp/main.tf.example).

---

## Service mapping (Design phase)

| GCP (Terraform type) | AWS target | Confidence | Rationale |
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

Generated AWS Terraform: [`terraform/`](./terraform/) (`main`, `compute`, `data`, `iam`,
`ai-bedrock`, `outputs` — all `.tf.example`).

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
   API Gateway/webhooks │ (Cloud Functions → Lambda)
      Lambda ───────────┘
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

> **Illustrative** us-east-1 on-demand estimate for the **prod** tier, credits
> **not** applied. Real numbers drift — the plugin pulls live pricing at run time, and
> on the actual Leverage layer you must re-run `make infracost-breakdown` before applying.
> Dev/staging is materially cheaper (single-AZ, Serverless v2, single NAT).

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

**Bedrock note:** meeting-summary token cost is usage-driven, not a fixed line item. At the
`gpt-4o` tier OpenAI can be ~29% cheaper per token, so the migration case is **provider
consolidation + IAM auth (no third-party API key) + Activate credits**, not raw token price.
Size it from real transcript volume during the eval.

**Activate credits:** the **$100k** tier comfortably covers this footprint for the credit
term — the plugin surfaces this as the primary near-term cost lever.

---

## Next step — this is NOT a Leverage layer yet

The `terraform/*.tf.example` files are the plugin's raw output. Turning them into a real
deployable layer means refactoring to repo conventions (see
[`MIGRATION_GUIDE.md`](./MIGRATION_GUIDE.md) → "Refactor to Leverage"):

- `config.tf` with the S3 backend + provider + remote-state data sources
- symlink `common-variables.tf -> ../../../config/common-variables.tf`
- `local.tags` block; drop the standalone `provider "aws"` and `default_tags`
- prefer **Leverage/Binbash modules** over raw resources where one exists
- add an `infracost.yml` entry and (if deployed) an `atlantis.yaml` project
- land it in the appropriate account/region (e.g. `apps-prd/us-east-1/<layer>`), **not**
  this documentation layer
