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
leverage aws sso login          # `leverage aws sso refresh` if the SSO token is still live
make version-support            # the PR gate
make version-support-table      # regenerate status.md
```

No AWS exports needed: the targets resolve them out of the repo, because nothing else
does. `leverage` exports `AWS_CONFIG_FILE` and `AWS_SHARED_CREDENTIALS_FILE` into every
command it runs, and `~/.aws/<project>/` is the only place this repo's SSO profiles
exist — but the scanner deliberately runs *outside* that wrapper, on its own `uv`
environment. The targets therefore supply those two paths, plus `AWS_PROFILE` and
`AWS_DEFAULT_REGION` read from `apps-devstg/config/backend.tfvars`. Any of the four
yields to a value you export yourself, so `AWS_PROFILE=bb-shared-devops make
version-support` scans as another account — any account works, these are catalog lookups.

Invoking the module directly — as CI and the test suite do — supplies none of that, so
locally it needs all four. CI gets its credentials and region from
`aws-actions/configure-aws-credentials` instead, which is why it never met any of this:

```bash
export AWS_CONFIG_FILE=~/.aws/bb/config                    # NOT ~/.aws/config
export AWS_SHARED_CREDENTIALS_FILE=~/.aws/bb/credentials   # NOT ~/.aws/credentials
export AWS_DEFAULT_REGION=us-east-1                        # NOT AWS_REGION
export AWS_PROFILE=bb-apps-devstg-devops
PYTHONPATH=@bin/scripts uv run --quiet \
  --with-requirements @bin/scripts/version_support/requirements.txt \
  python -m version_support --mode pr --root .
```

The region is the subtle one there, and it looks like success. boto3 reads it from
`AWS_DEFAULT_REGION` **only** — its variable chain is still
`('region', 'AWS_DEFAULT_REGION', None, None)` as of botocore 1.43 — whereas the AWS CLI
honours `AWS_REGION` too, so a shell exporting just that one runs `aws` fine and this
scanner not at all. Leverage writes each profile block with only `expiration = ...` and
no `region`, so there is no config-file fallback to catch it: naming a profile without
also setting the region is *worse* than naming no profile.

### Reading the warning

**Nothing below fails the run.** The scanner degrades instead, by design, so an AWS
outage never blocks a merge — a local run that checked nothing still exits 0, printing
only:

```text
::warning::version-support: AWS lookup unavailable - the check did NOT run (...)
```

**That line is the only difference between "all clear" and "never ran"** — the same
"green means did not run" trap as a fork PR, one shell away. Read it before trusting a
pass, and read *which* message it carries: they have different fixes, and the first two
are not credential expiry however much the wording suggests it.

| Message in the parentheses | What actually happened | Fix |
| --- | --- | --- |
| `Unable to locate credentials` | No credentials found **at all**: usually the default `~/.aws/credentials` was read instead of Leverage's, or the named profile exists in `config` but was never minted into `credentials` | Use the make targets, or export the two file paths above |
| `The config profile (X) could not be found` | `AWS_PROFILE` names a profile absent from that config file — including a permission set renamed out from under it | `leverage aws sso refresh`, or export a profile you actually hold |
| `An error occurred (ExpiredTokenException) ... security token ... is expired` | The credentials are genuinely stale. Leverage's per-profile credentials expire well before the SSO token does — and faster for short-session permission sets: `Administrator` mints 1h where `DevOps` mints 2h | `leverage aws sso refresh` — no browser, as long as the SSO token is live |
| `You must specify a region.` | No region resolved (see the `AWS_REGION` trap above) | `export AWS_DEFAULT_REGION=us-east-1` |

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
