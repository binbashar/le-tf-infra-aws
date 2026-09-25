# Container Registry (ECR)

## Overview

This layer manages the project's [Amazon ECR](https://aws.amazon.com/ecr/) container
image repositories. It follows the Leverage Reference Architecture's **consolidated**
model: ECR repositories live in the **Shared** account and are shared across the
organization. Images are built and pushed here once, and other accounts
(e.g. `apps-devstg`) are granted cross-account **pull (read)** access through repository
policies.

A corresponding container-registry layer is deployed in the secondary region
(`us-east-2`) for DR. Note it is **not an exact mirror**: this primary-region layer uses
the [`terraform-aws-ecr`](https://github.com/binbashar/terraform-aws-ecr) module
(`local.repositories`), whereas `us-east-2` uses the
[`terraform-aws-ecr-cross-account`](https://github.com/binbashar/terraform-aws-ecr-cross-account)
module (`local.repository_list`) with a different variable structure. No registry
replication rule is configured, so images are not copied between the two regions
automatically.

### What this layer configures

- **Repositories** (`ecr_repositories.tf` + `locals.tf`) — one repository per image, each
  with its own cross-account access ARNs (`read_access_arns` / `read_write_access_arns`).
- **Registry scanning** (`ecr_repositories.tf`) — account-wide `SCAN_ON_PUSH` (BASIC) for
  every repository.
- **Lifecycle policy** (`lifecycle_policy.tf`) — default rules keep the last 20 tagged
  images and expire images older than 90 days.

## Why consolidated, and when to evolve it

[#564](https://github.com/binbashar/le-tf-infra-aws/issues/564) proposed replacing this
model with a **per-environment (per-account)** one: every account owning its own
registry, with images pushed to DEV and replicated DEV → STG → PRD. After revisiting it
(July 2026), the decision is to **keep the consolidated model as the default** and not
pursue that refactor:

- **Start simple, evolve on demand.** The Reference Architecture begins with the simplest
  approach that works, and moves to a more complex one only when a concrete requirement
  (compliance, security, availability or cost) calls for it.
- **It fits the target.** For startups and small teams, one registry means one place for
  repository policies, lifecycle rules and scanning, and each image is built once and
  promoted unchanged (by digest) across environments.
- **Per-account from scratch is rarely the goal.** It duplicates configuration, fragments
  scanning and supply-chain controls, and multiplies storage. At scale, the common pattern
  is not full decentralization but a **hybrid** of both models.

The question to ask is not *"consolidated or per-account?"* but *"what problem is the
shared registry causing?"*. When one shows up, extend this layer into a **hybrid** model
rather than replacing it: the Shared registry stays the **source of truth**, where images
are built, scanned and signed, and only **approved** images are distributed to the
accounts that run them.

- **Production deploys depend on the Shared account** → give production a local registry,
  fed by [replication](https://docs.aws.amazon.com/AmazonECR/latest/userguide/replication.html)
  or an ECR-to-ECR [pull through cache](https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache.html)
  rule.
- **An unapproved or tampered image could reach production** → add a promotion gate:
  either a separate production registry (two registries, non-prod and prod — not one per
  account), or [image signing](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-signing.html)
  (AWS Signer, or Sigstore `cosign`) where non-prod builds are signed with a key that
  production does not trust, promotion adds the production signature, and deploys verify
  it.
- **Cross-account or cross-Region pull cost** → replicate once and pull locally. The same
  mechanism is the natural way to keep the `us-east-2` DR repositories in sync.

Native ECR replication filters on the **repository-name prefix** only, not on image tags,
so an approval- or tag-conditional STG → PRD promotion (as sketched in #564) needs a
pipeline step that copies the approved image digest.

## Modules

- This layer (`us-east-1`): [`terraform-aws-ecr`](https://github.com/binbashar/terraform-aws-ecr) — `v2.4.0`
- DR layer (`us-east-2`): [`terraform-aws-ecr-cross-account`](https://github.com/binbashar/terraform-aws-ecr-cross-account) — `1.1.0`

---

**Layer**: `shared/us-east-1/container-registry` (with a corresponding DR layer in `shared/us-east-2`)
