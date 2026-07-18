# GCP to AWS Migration Guide — Meridian

> Fictional worked example for the `aws-startup-advisor` `migration-to-aws` skill.
> This is the phase-based cutover runbook that the plugin's Generate phase produces,
> adapted to the Leverage workflow. See [`README.md`](./README.md) for the mapping,
> architecture, and cost estimate.

## Table of contents

1. [Prerequisites](#1-prerequisites)
2. [Provision AWS infrastructure](#2-provision-aws-infrastructure)
3. [Data migration](#3-data-migration)
4. [Application cutover](#4-application-cutover)
5. [AI cutover (OpenAI → Bedrock)](#5-ai-cutover-openai--bedrock)
6. [DNS cutover](#6-dns-cutover)
7. [Decommission GCP](#7-decommission-gcp)
8. [Refactor to Leverage](#refactor-to-leverage)

---

## 1. Prerequisites

**Pre-migration — root user security (do first):**

- **Enable root MFA** and store root credentials in a password manager; use root only for
  account recovery. **Delete any root access keys.**
- **Day-to-day access via IAM Identity Center** — in this repo that's the `management/global/sso`
  layer. Do not hand-roll IAM users.

**Tooling:** `terraform`/`tofu` ≥ 1.5, `aws-cli`, `gcloud`, `docker`, `jq`, `psql`, `pgcopydb`,
and (for the AI track) `python` ≥ 3.9 + `boto3`.

**Access:** AWS target account via Leverage SSO; GCP project export permissions on the source.

---

## 2. Provision AWS infrastructure

The example `terraform/` is illustrative raw output. On the real project you either apply it
standalone first (fast validation) **or** go straight to the Leverage refactor
([below](#refactor-to-leverage)) — recommended for anything that will live in this repo.

1. Stand up networking, data stores, compute (VPC → Aurora/ElastiCache/S3 → Fargate/Lambda).
2. Confirm Aurora, Redis, and S3 are reachable from the API security group.
3. Push the API container image to ECR; deploy the Fargate service (0 external traffic yet —
   ALB not fronting DNS).

## 3. Data migration

- **PostgreSQL (Cloud SQL → Aurora):** ~30 GB → **`pgcopydb`** (the skill picks the tool from
  DB size: `<10 GB` pg_dump; `10–500 GB` pgcopydb; `>500 GB` AWS DMS). Do an initial full copy,
  then a short cutover-window delta.
- **Object storage (GCS → S3):** `gcloud storage rsync` / `gsutil rsync` for the bulk copy, then
  a final sync during the cutover window. Re-point app upload paths to the S3 bucket.
- **Redis (Memorystore → ElastiCache):** cache is regenerable — no data migration; warm on
  cutover. If you must preserve keys, dump/restore.

## 4. Application cutover

1. Point app config at Aurora writer/reader endpoints + ElastiCache primary (Terraform outputs).
2. Move secrets into Secrets Manager (DB creds handled by Aurora `manage_master_user_password`).
3. Repoint Cloud Functions webhooks to the Lambda/API-Gateway endpoint.
4. Swap Pub/Sub publishes for SNS publishes; workers consume from SQS (DLQ configured).
5. Smoke-test end to end against the ALB hostname before touching DNS.

## 5. AI cutover (OpenAI → Bedrock)

> **Compatibility-guided, not 1:1.** Re-validate before flipping traffic.

1. Enable Bedrock model access for the target Claude model in the region.
2. Replace the OpenAI SDK call with the Bedrock **Converse API** (see
   [`terraform/ai-bedrock.tf.example`](./terraform/ai-bedrock.tf.example)); the worker task role
   gets `bedrock:InvokeModel`. **No API key** — IAM auth. Retire the `openai-api-key` secret.
3. Run the eval harness on a golden set of meeting transcripts — compare summary quality +
   latency vs `gpt-4o`.
4. Roll out behind a feature flag; ramp 5% → 50% → 100% while watching evals.

## 6. DNS cutover

1. In Route 53, create the app records pointing at the ALB (`alb_dns_name` output).
2. Lower TTLs 24–48h ahead. Delegate `meridian.app` to the Route 53 `route53_name_servers`
   at the registrar (or CNAME/alias-swap if keeping the registrar's DNS).
3. Watch error rates + latency; keep GCP warm for rollback until traffic is stable.

## 7. Decommission GCP

Only after a stable soak (suggest ≥1 week): scale Cloud Run to 0, disable Cloud Functions,
snapshot then delete Cloud SQL, empty then delete GCS buckets, remove the OpenAI key. Keep
final DB snapshots per your retention policy.

---

## Refactor to Leverage

The generated Terraform is a **starting point**, not repo-ready. Before it becomes a layer:

| Plugin output | Leverage convention |
|---|---|
| standalone `provider "aws"` + `default_tags` | `config.tf` provider + backend; `local.tags` (`Terraform`/`Environment`/`Layer`) |
| hardcoded region/name locals | `common-variables.tf` symlink + `config/*.tfvars` hierarchy |
| raw `hashicorp/aws` resources | **Binbash/Leverage modules** where one exists (VPC, RDS, etc.) |
| no state wiring | S3 backend + DynamoDB lock; remote-state data sources for cross-layer refs |
| no cost/CI wiring | add `infracost.yml` entry; add `atlantis.yaml` project if deployed |
| lives in a scratch dir | land in `apps-prd/us-east-1/<layer>` (or the right account/region) |

Then follow the normal flow: `leverage tofu init` → `plan` → **redacted plan to a PR** (see repo
[CLAUDE.md](../../../../../CLAUDE.md#standard-workflow-posting-a-tofu-plan-to-a-pr-for-review)) →
human review → `leverage tofu apply`.
