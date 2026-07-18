# Container Registry (ECR)

## Overview

This layer manages the project's [Amazon ECR](https://aws.amazon.com/ecr/) container
image repositories. It follows the Leverage Reference Architecture's current
**consolidated** model: ECR repositories live in the **Shared** account and are shared
across the organization. Images are built and pushed here once, and other accounts
(e.g. `apps-devstg`) are granted cross-account **pull (read)** access through repository
policies.

The same layer is deployed in the primary region (`us-east-1`) and, for DR, in the
secondary region (`us-east-2`).

### What this layer configures

- **Repositories** (`ecr_repositories.tf` + `locals.tf`) — one repository per image, each
  with its own cross-account access ARNs (`read_access_arns` / `read_write_access_arns`).
- **Registry scanning** (`ecr_repositories.tf`) — account-wide `SCAN_ON_PUSH` (BASIC) for
  every repository.
- **Lifecycle policy** (`lifecycle_policy.tf`) — default rules keep the last 20 tagged
  images and expire images older than 90 days.

## Consolidated vs. per-environment ECR

The **consolidated** approach above centralizes all repositories in the Shared account.
An alternative **per-environment (per-account)** approach is being evaluated: each account
would own its own ECR repositories, images would be built/pushed to the dev registry, and
cross-account/cross-region **replication** would propagate them downstream (e.g.
DEV → STG → PRD, optionally conditional on tags or other logic). See
[binbashar/le-tf-infra-aws#564](https://github.com/binbashar/le-tf-infra-aws/issues/564)
for the rationale.

## Documentation

A detailed feature write-up comparing the **consolidated** and **per-environment** ECR
approaches lives in the Leverage documentation, under the AWS Reference Architecture
**Features** section:

- [Leverage Reference Architecture — Features](https://leverage.binbash.co/user-guide/ref-architecture-aws/features/)

## Module

- [`terraform-aws-ecr`](https://github.com/binbashar/terraform-aws-ecr) — `v2.4.0`

---

**Layer**: `shared/us-east-1/container-registry` (mirrored in `shared/us-east-2`)
