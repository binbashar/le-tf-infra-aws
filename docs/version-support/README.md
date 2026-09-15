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
| PR touching `**/*.tf` or the resolved `*.tfvars` | **Fails** if an *active* layer pins a version already in extended support; warns at ≤ 90 days |
| PR **from a fork** | Not gated at all. A fork gets no secrets, so the scanner is skipped entirely and the job still reports success — its green check means "did not run", not "passed" |
| Monthly (1st, 07:23 UTC) | Never fails. Posts to Slack and opens/updates one tracking issue |
| `workflow_dispatch` | Same as the monthly sweep |

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
export AWS_DEFAULT_REGION=us-east-1        # NOT AWS_REGION -- see below
make version-support            # the PR gate
make version-support-table      # regenerate status.md
```

Two traps here, and both of them look like success:

- **`AWS_DEFAULT_REGION`, not `AWS_REGION`.** boto3 reads the region from `AWS_DEFAULT_REGION`
  only — its variable chain is still `('region', 'AWS_DEFAULT_REGION', None, None)` as of
  botocore 1.43 — whereas the AWS CLI honours both. A shell that exports just `AWS_REGION`
  therefore runs `aws` fine and this scanner not at all. Leverage writes each profile block
  with only `expiration = ...` and no `region`, so there is no config-file fallback to catch
  it: naming a profile without also setting the region is *worse* than naming no profile.
- **Stale credentials.** Leverage's per-profile credentials expire well before the SSO token
  does, and `credential_process` indirection reports that as `Unable to locate credentials`.
  Re-mint with `leverage aws sso refresh` — no browser, as long as the SSO token is still
  live — rather than reaching for `leverage aws sso login`.

Neither case fails the run: the scanner degrades instead, by design, so that an AWS outage
never blocks a merge. A local run that checked nothing still exits 0, printing only:

```text
::warning::version-support: AWS lookup unavailable - the check did NOT run (...)
```

**That line is the only difference between "all clear" and "never ran"** — the same
"green means did not run" trap as a fork PR, one shell away. Read it before trusting a pass.

## IAM

Two read-only actions, and nothing else: `eks:DescribeClusterVersions` and
`rds:DescribeDBMajorEngineVersions`. Both describe AWS's *version catalog* rather than the
caller's resources, so any account works. CI assumes `DeployMaster` in `apps-devstg`, which
already grants `eks:*` and `rds:*` — **no IaC change was needed** for this guardrail.

That reuse is a deliberate trade-off, not a clean win: `DeployMaster` is far broader than the two
actions the scanner uses, so a compromised CI job could reach well beyond version lookups. A
dedicated least-privilege role scoped to exactly those two actions is the better end state and is
tracked as a follow-up; it was kept out of this change so the guardrail could land without
requiring an `apply` first.
