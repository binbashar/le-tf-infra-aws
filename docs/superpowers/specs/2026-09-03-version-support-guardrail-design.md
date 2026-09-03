# Version-support guardrail — EKS / RDS extended-support surcharges

- **Date:** 2026-09-03
- **Issue:** [binbashar/le-tf-infra-aws#1160](https://github.com/binbashar/le-tf-infra-aws/issues/1160) — Guardrail against EKS/RDS extended-support cost surcharges
- **Scope of this spec:** the repository-side guardrail — a version-pin scanner, a PR gate, a weekly sweep, and the docs they produce. The billing-side detection is already delivered by the `aws-finops` plugin adopted in #1159 and is explicitly out of scope here.
- **Status:** approved for planning

## Problem

AWS bills **extended support** for a Kubernetes version or an RDS/Aurora major engine version that has passed its end-of-standard-support date:

- **EKS:** `$0.60` per cluster-hour instead of `$0.10` — roughly **+$365 per cluster per month**, charged **per cluster**, so it scales with cluster count rather than workload size.
- **RDS / Aurora:** a per-vCPU-hour charge **on top of** the instance price, which increases again in the third year.

It is a **rate** change on unchanged infrastructure, starting on a specific date. That has two consequences: nothing to right-size means neither Compute Optimizer nor Cost Optimization Hub reports it, and a naive month-over-month read blames "EKS grew" rather than "we are paying the late fee."

[#547](https://github.com/binbashar/le-tf-infra-aws/issues/547) fixed this once by bumping versions and closed. That is the problem this spec addresses: it is a recurring deadline, and nothing in the reference architecture warns us *before* the surcharge starts.

## Key findings that shape the design

Four facts, established against the repository and the AWS docs, drove every decision below.

**1. Both lifecycles are queryable by version, without the resource existing.** These are *catalog* lookups — they describe AWS's version catalog, not the caller's resources:

- [`eks:DescribeClusterVersions`](https://docs.aws.amazon.com/eks/latest/APIReference/API_ClusterVersionInformation.html) returns `endOfStandardSupportDate`, `endOfExtendedSupportDate`, and `versionStatus` (`STANDARD_SUPPORT` / `EXTENDED_SUPPORT` / `UNSUPPORTED`).
- [`rds:DescribeDBMajorEngineVersions`](https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DescribeDBMajorEngineVersions.html) returns `SupportedEngineLifecycles` with a lifecycle name and start/end dates.

This removes any need for a hand-maintained table of end-of-life dates — the single most likely thing to rot — and means one account's read-only credentials cover the whole scan.

**2. The real surface is smaller than the issue implies, and it is not where you would look.**

| | Finding |
| --- | --- |
| Active EKS | Exactly one: `apps-devstg/us-east-1/k8s-eks-demoapps/cluster`, pinned `1.34` (current) |
| `apps-devstg/us-east-2/k8s-eks-v1.17` | **Not a layer** — zero tracked files; only stale `.infracost` module cache remains |
| Active RDS / Aurora | **None.** All five `databases-*` layers are disabled by the `--` suffix convention |
| Disabled DB pins | `aurora-mysql 5.7`, `aurora-postgresql 14.8`, `postgres 14.18`, `mysql 8.0.41` — stale |

The live cluster is not the near-term risk. **Re-enabling a dormant database layer whose pin is already past end-of-standard-support is**, and no scan of *deployed* infrastructure would ever see it. The scanner therefore reads **code**, including disabled layers.

**3. The pins are not where a naive scan would find them, and there are real look-alikes.** The EKS version is a `variables.tf` **default** (`cluster_version = "1.34"`), not a literal at the resource — so variable resolution is mandatory, not a nicety. Meanwhile a plain `engine_version` grep also matches `apps-devstg/us-east-1/elasticache-redis`, `data-science/us-east-1/datalake-demo--/dms.tf` (`repl_instance_engine_version = "3.5.3"`) and OpenSearch, none of which carry an extended-support surcharge. A false positive that hard-fails a PR would get the check disabled within a week.

**4. No IaC changes are required.** `apps-devstg`'s `DeployMaster` role already grants `eks:*` and `rds:*` (`apps-devstg/global/base-identities/policies.tf`), and `.github/workflows/leverage-cli-test.yml` already demonstrates assuming it from CI with the existing `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_DEVSTG_ACCOUNT_ID` secrets. The guardrail reuses that path unchanged.

## Chosen approach

A Python scanner plus one GitHub Actions workflow:

- **PR gate** on changes to `**/*.tf` — hard-fail when an **active** layer pins a version already in extended support, warn at ≤ 90 days. This is what blocks the re-enable-a-stale-layer case at merge time.
- **Weekly sweep** (cron + `workflow_dispatch`) — never fails the repo; reports to Slack and opens or updates a single GitHub issue when anything crosses the lead-time line.

Rejected alternatives, and why:

| Alternative | Why not |
| --- | --- |
| Cost Anomaly Detection / CloudWatch alarm on `USAGE_TYPE ~ ExtendedSupport` | Detection, not prevention — it fires the month the surcharge already started. The `aws-finops` plugin from #1159 already reports this from the bill. |
| Generated doc plus a recurring review item, no automated gate | Relies on someone reading it on the right week. The deadline is the whole problem. |
| Weekly cron only, no PR gate | A stale pin can merge and go unnoticed for up to a week. |
| Hard-fail on the weekly cron too | A permanently red scheduled run normalises being ignored. |

## Placement

```
scripts/version_support/          # new; the repo has no scripts/ dir today
├── __main__.py                   # CLI: --mode pr|cron|table, --lead-days
├── discover.py                   # tree  → [Pin]      HCL parse, never touches AWS
├── lifecycle.py                  # [Pin] → [Finding]  AWS lookup, never touches the filesystem
├── report.py                     # [Finding] → terminal / annotations / markdown / Slack / issue body
├── requirements.txt              # python-hcl2, boto3
└── tests/
    ├── fixtures/                 # tiny .tf trees, one per discovery case
    ├── test_discover.py
    └── test_lifecycle.py

docs/version-support/
├── README.md                     # why, the upgrade cadence, how to run, IAM used
└── status.md                     # GENERATED — carries a "generated <date>" line

.github/workflows/version-support.yml
```

The three-module split is the testability boundary: `discover` is a pure function of the tree, `lifecycle` is a pure function of `[Pin]` plus AWS, `report` is pure formatting. Each can be tested without standing up the other two.

Invocation is `PYTHONPATH=scripts python -m version_support --mode <mode>`, wrapped in `Makefile` targets so local use matches CI.

## Architecture

```
                     *.tf across all account/region/layer paths
                                      │
                            discover.py │ (python-hcl2)
        ┌─────────────────────────────┴─────────────────────────────┐
        │                                                           │
  cluster_version                                        engine ∈ allow-list
  literal, or var.cluster_version                        {mysql, postgres,
  resolved to its variables.tf default                    aurora-mysql,
        │                                                 aurora-postgresql}
        │                                                  → sibling engine_version
        │                                    (elasticache / opensearch / dms never match:
        │                                     their engine value is not in the allow-list)
        └─────────────────────────────┬─────────────────────────────┘
                                      ▼
                    [Pin(kind, engine, version, layer, active, source)]
                        active = False when a path segment ends with "--"
                                      │
                           lifecycle.py │ (boto3, cached per (kind, engine, version))
                    ┌─────────────────┴─────────────────┐
        eks:DescribeClusterVersions        rds:DescribeDBMajorEngineVersions
                    └─────────────────┬─────────────────┘
                                      ▼
              [Finding(pin, status, end_standard, days_left, severity)]
                                      │
                             report.py │
             ┌────────────────┬────────┴────────┬─────────────────┐
      terminal table    GH annotations     docs/…/status.md   Slack + issue body
```

## Components

| File | Responsibility |
| --- | --- |
| `discover.py` | Walk the tree, parse each layer's `.tf` with `python-hcl2`, resolve `var.<name>` (see *Version resolution* below), pair an allow-listed `engine` with the `engine_version` in the same block, and mark disabled layers (see *The disabled-layer rule* below). Yields `Pin`. Never calls AWS. |
| `lifecycle.py` | Given `[Pin]`, call the two AWS APIs once per distinct `(kind, engine, version)` and classify. Yields `Finding`. Never reads the filesystem. |
| `report.py` | Pure formatting over `[Finding]`: terminal table, GitHub `::warning` / `::error` annotations, the generated markdown table, the Slack payload, and the issue body. |
| `__main__.py` | Argument parsing, mode dispatch, exit codes. The only place that decides whether a run fails. |

### The disabled-layer rule

A layer is disabled when **any path segment ends with `--`**. Both forms occur in this
repository and the rule must match both: ` --` with a leading space (`databases-mysql --`,
`security-hub --`) and `--` attached directly (`databases-dynamodb--`, `datalake-demo--`,
`bedrock-agent--`). `CLAUDE.md` documents only the spaced form, so a rule written from the
docs alone would silently treat several disabled layers as active — and hard-fail PRs on
dormant infrastructure. Match on the trailing `--`, not on `" --"`.

### Version resolution

A pin's version is resolved in this order, first match wins:

1. A literal at the resource or module argument (`cluster_version = "1.34"`).
2. `var.<name>` → an override in `config/common.tfvars` or `{account}/config/account.tfvars`.
3. `var.<name>` → the `default` in the layer's `variables.tf`.

No `.tfvars` in the tree currently sets either variable, so step 3 is what resolves the one
active EKS pin today. Step 2 exists anyway because skipping it would report a stale default
while a tfvars override supplies the real value — a **false negative**, which is the failure
this guardrail must not have. A `var` that resolves through none of the three yields
`UNKNOWN`; it is never assumed safe.

### Data model

```python
@dataclass(frozen=True)
class Pin:
    kind: str            # "eks" | "rds"
    engine: str | None   # None for EKS; "aurora-mysql" etc. for RDS
    version: str         # "1.34" | "5.7"
    layer: str           # "apps-devstg/us-east-1/k8s-eks-demoapps/cluster"
    active: bool         # False when any path segment ends with "--"
    source: str          # "…/variables.tf:9 (var default)" — shown in every report

@dataclass(frozen=True)
class Finding:
    pin: Pin
    status: str                  # STANDARD_SUPPORT | EXTENDED_SUPPORT | UNSUPPORTED | UNKNOWN
    end_standard: date | None
    end_extended: date | None
    days_left: int | None        # to end_standard
    severity: str                # OK | SOON | EXTENDED | UNSUPPORTED | UNKNOWN
```

`source` is carried all the way to the report on purpose: a finding that says *which file and line* to edit is actionable; one that names only a layer sends the reader hunting.

## Classification

| Severity | Condition |
| --- | --- |
| `UNSUPPORTED` | AWS reports the version unsupported |
| `EXTENDED` | Already in extended support — surcharge billing now |
| `SOON` | `days_left ≤ 90` (overridable with `--lead-days`) |
| `UNKNOWN` | AWS returned nothing for that version, or the pin would not resolve |
| `OK` | Otherwise |

## Modes and exit behavior

| Mode | Fails? | Behavior |
| --- | --- | --- |
| `pr` | **Yes** — on any **active** `EXTENDED` or `UNSUPPORTED` | `::warning` annotations for active `SOON` and for all `UNKNOWN`. Disabled-layer findings print as notes and can never affect the exit code. |
| `cron` | **Never** | Posts to `SLACK_DIRECT_WEBHOOK` and opens-or-updates one GitHub issue when any **active** finding is `SOON` or worse. Latent disabled-layer debt is listed in the body but never triggers a notification on its own. |
| `table` | No | Regenerates `docs/version-support/status.md`. |

### Why disabled layers never fail

All five `databases-*` layers are disabled and carry stale pins, so gating on them would land the check red on day one and keep it red — the reliable path to a check being switched off. Instead they appear as standing latent debt ("would be in extended support if enabled"), and the moment a PR removes a ` --` suffix, that layer is **active** and the gate fails on it right there. Visibility without day-one noise, and the enforcement point is exactly where the risk materialises.

### One issue, not fifty-two

The weekly job embeds a marker comment (`<!-- version-support-guardrail -->`) in the issue body and searches for an open issue carrying it. Found means update; not found means create. Labels: `cost-optimization`, `enhancement`.

## Error handling

The failure mode that matters most is a check that silently passes when it could not run.

| Failure | `pr` mode | `cron` mode |
| --- | --- | --- |
| AWS call fails (expired creds, throttling, outage) | Exit **0** with a loud warning annotation — never block merges on an AWS outage | Post *"check could not run"* to Slack, so silence is never mistaken for all-clear |
| HCL parse error in a file | That layer yields `UNKNOWN`; the scan continues | Same |
| Pin will not resolve (see *Version resolution*) | `UNKNOWN`, warned — never silently skipped | Same |
| **Fork PR** — this repo is public, so `pull_request` from a fork receives no secrets and cannot assume the role | Detect the missing credentials, skip the AWS phase, and exit **0** with a notice saying the check did not run. `discover.py` still runs, so parse errors and unresolvable pins are still reported | n/a — the cron only runs on `master` |

## Testing

| Test | Covers |
| --- | --- |
| `test_discover.py` | Variable-default resolution (the EKS case in this repo); a literal pin; ` --` disabled detection; engine/version pairing within one block; multiple pins in one layer; and the three look-alikes — `elasticache-redis`, `dms`, OpenSearch — staying unmatched |
| `test_lifecycle.py` | Each severity boundary (`OK` / `SOON` / `EXTENDED` / `UNSUPPORTED`) via `botocore.stub.Stubber`; the unknown-version path; the API-failure path |

Fixtures are tiny `.tf` trees under `tests/fixtures/`, mirroring the shapes actually present in this repository rather than invented ones. Pytest runs in the same workflow on PRs, so the guardrail's own logic is gated by the same PR it ships in.

## Workflow

`.github/workflows/version-support.yml`:

- **Triggers:** `pull_request` (paths `**/*.tf`), `schedule` at `23 7 * * 2` (Tuesdays 07:23 UTC — deliberately off the existing lint sweep's Monday `17 6 * * 1` so a red morning has one cause, not two), and `workflow_dispatch`.
- **Permissions:** `contents: read` plus `issues: write` — the cron opens or updates an issue, which the default read-only `GITHUB_TOKEN` cannot do.
- **Steps:** checkout → set up Python → install `requirements.txt` → run pytest → configure AWS credentials by assuming `DeployMaster` in `apps-devstg` (the pattern already in `leverage-cli-test.yml`) → run the scanner in the mode matching the trigger.

## Documentation

- `docs/version-support/README.md` — why the guardrail exists, the **upgrade cadence** tied to the [Kubernetes release calendar](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html#kubernetes-release-calendar) (including the one-minor-hop-at-a-time constraint already documented in `cluster/variables.tf`), how to run the scanner locally, and the IAM it uses.
- `docs/version-support/status.md` — the generated table, marked generated and carrying the date it was produced so staleness is visible on sight.
- Cross-links: `docs/finops/README.md` (detection ↔ prevention) and the `CLAUDE.md` FinOps section.

The committed table is refreshed on demand via its `Makefile` target — which happens naturally in any PR that bumps a version. The weekly job regenerates it in memory and embeds the fresh table in the issue body, so the report is never stale even when the committed copy is.

## Out of scope

- **Any IaC change.** Verified unnecessary — see key finding 4.
- **A billing-side alarm.** #1159's `aws-finops` plugin already detects and prices the surcharge from `USAGE_TYPE`; duplicating it in OpenTofu adds a second thing to maintain for the same signal.
- **Scanning live clusters.** The risk this guardrail addresses lives in code, including in layers that are not deployed.
- **Auto-bumping versions.** EKS allows only one minor hop at a time, each applied and verified before the next; that is human work.
- The DevOps/Security frontier agents, and everything else in #1003 / #1159.

## References

- [EKS extended support pricing announcement](https://aws.amazon.com/blogs/containers/amazon-eks-extended-support-for-kubernetes-versions-pricing/)
- [Kubernetes version lifecycle on EKS](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)
- [`ClusterVersionInformation`](https://docs.aws.amazon.com/eks/latest/APIReference/API_ClusterVersionInformation.html) · [`DescribeDBMajorEngineVersions`](https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DescribeDBMajorEngineVersions.html)
- Supersedes the one-off remediation in [#547](https://github.com/binbashar/le-tf-infra-aws/issues/547); overlaps [#997](https://github.com/binbashar/le-tf-infra-aws/issues/997) (the *next* EKS upgrade); detection side delivered by [#1159](https://github.com/binbashar/le-tf-infra-aws/issues/1159)
