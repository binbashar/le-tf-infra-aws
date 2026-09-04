# Version support — EKS / RDS extended-support guardrail

AWS bills **extended support** for a Kubernetes version or an RDS/Aurora major engine
version past its end-of-standard-support date: EKS at `$0.60` per cluster-hour instead of
`$0.10` (**≈ +$365 per cluster per month**, charged *per cluster*), RDS/Aurora per vCPU-hour
on top of the instance price, increasing again in year three.

It is a **rate** change on unchanged infrastructure, so there is nothing to right-size and
neither Compute Optimizer nor Cost Optimization Hub reports it.

This guardrail is the **prevention** side. The **detection** side — catching the surcharge
on the bill via `USAGE_TYPE` — is the `aws-finops` plugin, see [`docs/finops/`](../finops/).

## What runs, and when

| Trigger | Behavior |
| --- | --- |
| PR touching `**/*.tf` | **Fails** if an *active* layer pins a version already in extended support; warns at ≤ 90 days |
| Weekly (Tuesdays 07:23 UTC) | Never fails. Posts to Slack and opens/updates one tracking issue |
| `workflow_dispatch` | Same as the weekly sweep |

Disabled layers (those whose directory ends in `--`) are scanned and reported as latent
debt but **never** fail the check — gating on five dormant database layers would land the
check red on day one. The moment a PR removes the `--` suffix, that layer counts as active
and the gate applies.

## Current status

See [`status.md`](status.md), regenerated with `make version-support-table`.

## Upgrade cadence

Kubernetes minor versions leave standard support roughly **14 months** after release; see
the [EKS release calendar](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html#kubernetes-release-calendar).

- **Plan the bump when the check first warns** (90 days out), not when it fails. The cheapest
  fix is the early one; the surcharge starts the day standard support ends.
- **EKS allows only one minor hop at a time.** Each bump is applied and verified before the
  next, so catching up from three versions behind is three sequential applies — budget for
  it rather than discovering it under time pressure. This constraint is also noted in
  `apps-devstg/us-east-1/k8s-eks-demoapps/cluster/variables.tf`.
- **Never land a substrate change and a version bump in the same apply.** The AL2 → AL2023
  migration was deliberately done while still on 1.31 for this reason.
- **RDS/Aurora major upgrades** are not one-hop-constrained but do require a maintenance
  window and a tested rollback; treat the 90-day warning as the trigger to schedule one.

## Running it locally

```bash
# uv is already a prerequisite for this repo; the targets build their own
# environment on demand, so there is no venv to create or activate.
export AWS_PROFILE=bb-apps-devstg-devops   # any account works: these are catalog lookups
make version-support            # the PR gate
make version-support-table      # regenerate status.md
```

## IAM

Two read-only actions, and nothing else: `eks:DescribeClusterVersions` and
`rds:DescribeDBMajorEngineVersions`. Both describe AWS's *version catalog* rather than the
caller's resources, so any account works. CI assumes `DeployMaster` in `apps-devstg`, which
already grants `eks:*` and `rds:*` — **no IaC change was needed** for this guardrail.
