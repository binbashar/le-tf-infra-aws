# FinOps — AWS cost analysis for the Reference Architecture

How we analyse **actual** AWS spend for the binbash Organization: the
[`aws-finops`](https://github.com/binbashar/bb-ai-marketplace/tree/master/plugins/aws-finops)
Claude Code plugin, the AWS-side prerequisites this repo provisions for it, and
the reports it drops in this directory.

> **Scope.** This is about money already spent — reading the payer account's bill.
> For estimating the cost of a *proposed* change before applying it, use
> `make infracost-breakdown` or the `aws-cost-estimation` plugin instead.

---

## 1. What the plugin gives us

| Skill | Answers | Output |
| --- | --- | --- |
| **`/aws-finops-investigate`** | *What is happening with the bill?* — baseline + month-over-month deltas, anomaly triage, tag hygiene, end-of-month forecast vs budget | `finops-investigation-<ts>.md` (here) |
| **`/aws-finops-optimize`** | *How do we reduce it?* — right-sizing & idle resources, Savings Plans coverage/utilisation, per-service waste (incl. EKS/RDS extended-support surcharges) | `finops-optimization-<ts>.md` (here) |
| **`/leverage-aws-creds-check --management-only`** | Read-only SSO/credentials preflight; gates the two above | terminal table |

Every figure comes from the bundled **`awslabs.billing-cost-management-mcp-server`**
MCP server. The skills are **MCP-only by design and never fall back to the AWS
CLI**, so a report is reproducible rather than improvised.

> **Distinct from the AWS FinOps Agent.** `management/global/aws-finops-agent`
> (issue #1003, [PR #1115](https://github.com/binbashar/le-tf-infra-aws/pull/1115))
> provisions AWS's own managed frontier agent. The two coexist — this plugin's
> method is what you would feed that agent as custom instructions.

---

## 2. Prerequisites

### 2.1 Local tooling

| Requirement | Check | Install |
| --- | --- | --- |
| `uv` / `uvx` — runs the MCP server | `uvx --version` | `brew install uv` or `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Plugin enabled | `aws-finops@bb-ai-marketplace` in [`.claude/settings.json`](../../.claude/settings.json) | already committed |

The marketplace is pinned to a released tag in the same file
(`extraKnownMarketplaces.bb-ai-marketplace.source.ref`). Bump that pin to adopt a
newer plugin version; don't track a branch.

### 2.2 AWS side — what this repo provisions

The plugin reads the **management (payer) account** only. Consolidated billing
means it already sees every member account's cost; member spend is attributed via
the Cost Explorer `LINKED_ACCOUNT` dimension.

| Prerequisite | Where it is managed |
| --- | --- |
| Cost Explorer | Enabled account-wide (no OpenTofu resource exists; activated once in the console) |
| Cost Anomaly Detection monitor | `management/global/aws-finops-agent/cost-anomaly.tf` — `aws_ce_anomaly_monitor` — **pending [PR #1115](https://github.com/binbashar/le-tf-infra-aws/pull/1115)** |
| Compute Optimizer opt-in | `management/global/aws-finops-agent/compute-optimizer.tf` — `aws_computeoptimizer_enrollment_status` — **pending [PR #1115](https://github.com/binbashar/le-tf-infra-aws/pull/1115)** |
| Cost Optimization Hub — org trusted access | [`management/global/organizations/organization.tf`](../../management/global/organizations/organization.tf) — `cost-optimization-hub.bcm.amazonaws.com` in `aws_service_access_principals` |
| Cost Optimization Hub — org-wide enrollment | [`management/global/organizations/cost_optimization_hub_enabling.tf`](../../management/global/organizations/cost_optimization_hub_enabling.tf) — `aws_costoptimizationhub_enrollment_status` |
| Read-only IAM for the plugin | [`management/global/base-identities/role_policies.tf`](../../management/global/base-identities/role_policies.tf) — `aws_iam_policy.aws_finops_readonly_access`, attached to `DeployMaster` |

Each service takes **24–48 h to populate data** after first activation, so a run
immediately after enabling one will legitimately come back empty. Until PR #1115
merges and applies, `/aws-finops-investigate`'s anomaly phase and
`/aws-finops-optimize`'s right-sizing phase have no source data — the rest of both
reports still works.

> The `Administrator` SSO permission set already covers every call the plugin
> makes. `aws_finops_readonly_access` exists so the plugin can also run under
> `DeployMaster` — and so the exact permission surface is git-visible rather than
> hiding behind `AdministratorAccess`.

---

## 3. Running a report

The MCP server inherits `AWS_PROFILE` / `AWS_CONFIG_FILE` /
`AWS_SHARED_CREDENTIALS_FILE` **from the shell that launched Claude Code**, so the
management profile has to be exported *before* the session starts — you cannot fix
it from inside one.

```bash
leverage aws sso login                                    # ~8 h token

# refresh per-profile creds (any management layer will do)
cd management/global/organizations && leverage tofu refresh-credentials && cd -

export AWS_CONFIG_FILE="$HOME/.aws/bb/config"
export AWS_SHARED_CREDENTIALS_FILE="$HOME/.aws/bb/credentials"
export AWS_PROFILE="bb-management-administrator"          # or bb-management-devops

claude                                                    # restart the session
```

Then, in the session:

```text
/leverage-aws-creds-check --management-only   # must pass first
/aws-finops-investigate
/aws-finops-optimize
```

Each skill writes its report into this directory. **Commit them** — the point of
keeping them in-tree is diffing this month's run against the last one.

> **Cost note.** The Cost Explorer API charges **$0.01 per request**; a full run is
> ~10–20 calls, so **$0.10–$0.20 per report**. Not free, not a reason to hesitate.

---

## 4. Keeping runs about *new* findings

Two optional files suppress noise. Both are read as **Phase 0** of their skill, and
both change only how a charge is *described* or whether it is *recommended* — never
whether it is *counted* in totals and forecasts.

| File | Read by | Suppresses |
| --- | --- | --- |
| [`known-charges.md`](known-charges.md) | `/aws-finops-investigate` | Recurring charges we already know about, so they stop showing up as "biggest movers" and anomalies |
| [`accepted-exceptions.md`](accepted-exceptions.md) | `/aws-finops-optimize` | Spend we have reviewed and consciously accepted, so it stops being re-recommended |

`accepted-exceptions.md` rows carry a **Baseline ($/mo)**; if an accepted item grows
materially past it, the skill surfaces it as *"accepted, now growing"* rather than
hiding a ballooning cost. `known-charges.md` deliberately records **no amounts** —
the skill sanity-checks a known charge against its own recent months instead, so a
charge that doubles under a familiar name still gets noticed.

Add a row whenever a report flags something the team decides is expected. That is
the maintenance loop.

---

## 5. Reading a report

- **Marketplace / partner charges break the forecast.** Cost Explorer's end-of-month
  forecast is built from usage trends and does **not** include a monthly AWS
  Marketplace subscription that bills on a fixed day. If the org carries one, add it
  to the forecast by hand before comparing against a budget.
- **A rate change is not usage growth.** A service whose usage quantity is flat while
  cost steps up on a specific date has repriced — most often an EKS cluster or
  RDS/Aurora engine that crossed its end-of-standard-support date and now bills the
  extended-support surcharge (issue #1160 tracks preventing that in the IaC). Report
  it as a monthly/annualised run-rate step, not a one-off anomaly.
- **Tag coverage bounds attribution.** The investigate skill's tag-hygiene phase
  measures exactly what issue #842 (tagging strategy) is about; untagged spend is
  spend nobody can be asked to own.
