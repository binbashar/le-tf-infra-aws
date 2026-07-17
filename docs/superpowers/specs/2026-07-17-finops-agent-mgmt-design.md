# AWS FinOps Agent — `management/global/finops-agent` layer design

- **Date:** 2026-07-17
- **Issue:** [binbashar/le-tf-infra-aws#1003](https://github.com/binbashar/le-tf-infra-aws/issues/1003) — Implement and test AWS DevOps, Security and FinOps frontier agents
- **Scope of this spec:** the **FinOps Agent** only. The DevOps and Security frontier agents from #1003 are out of scope and get their own specs.
- **Status:** approved for planning

## Problem

AWS launched the [AWS FinOps Agent](https://aws.amazon.com/finops-agent/) (preview) — an AI agent that answers cost questions, investigates cost anomalies to root cause, and surfaces optimization recommendations, with optional Jira/Slack integrations. We want to stand it up in the **management (payer)** account and manage as much of it as possible with our IaC (OpenTofu via Leverage), consistent with the rest of this repo.

## Key finding that shapes the design

The original framing was "if OpenTofu doesn't support it, fall back to AWS CDK (more current)." Investigation showed that framing does not apply here:

- The agent instance — an **agentspace** — is created only through a **preview API**, `finops-agent:CreateAgentSpace`.
- **No CloudFormation resource type exists** (`AWS::FinOps::*` / `AWS::FinOpsAgent::*` are absent from the CFN resource reference).
- Because CDK and the Terraform/OpenTofu `awscc` (Cloud Control) provider are both **generated from the CloudFormation registry**, the absence of a CFN type means **neither CDK nor `awscc` can create the agentspace either**.
- The plain `hashicorp/aws` provider has **no `aws_finops*` resource** (confirmed against the installed provider 5.100 changelog).

Conclusion: **CDK offers no capability advantage over OpenTofu for this service**, while it would add a foreign toolchain (Node, `cdk bootstrap`, separate state, no Leverage/Atlantis/Infracost integration) to a 100%-OpenTofu repo. The agentspace is unsupported *everywhere*, so it is the one manual step regardless of tool.

What **is** fully IaC-able today with the plain `hashicorp/aws` provider is the meaningful surface: the two IAM roles the service assumes, their permission policies, and the feature prerequisites. The creation wizard explicitly supports **"use an existing role"** in Steps 2 and 3, so OpenTofu creates the roles and the one-time `CreateAgentSpace` merely selects them.

## Chosen approach

**Approach A — OpenTofu layer for everything IaC-able + one documented manual step.**

Rejected alternatives:
- **B (AWS CDK layer):** can only recreate the same IAM roles/prereqs OpenTofu already does natively (agentspace still unsupported) — foreign toolchain, zero extra capability.
- **C (fully manual):** leaves IAM roles and prerequisites unmanaged and drifting, against the repo's IaC-first principle.

### Prerequisite scope (decided)

**Roles + Cost Anomaly monitor + Compute Optimizer opt-in (management account only).**

- Cost Anomaly Detection monitor — enables the agent's headline anomaly-investigation feature; org-wide consolidated billing is visible from the payer account.
- Compute Optimizer opt-in scoped to the management account only (`include_member_accounts = false`) — enables rightsizing recommendations. Management has little compute, so value is limited, but it exercises the full agent feature set end-to-end and is a natural place to later flip to org-wide.

## Placement

`management/global/finops-agent/` — beside the existing billing-owned globals (`cost-mgmt`, `cost-report`, `organizations`).

In `management/global/*`, `var.region` resolves to **us-east-1** via `management/config/backend.tfvars` (`region = "us-east-1"`), which is what Cost Explorer, Cost Anomaly Detection, Compute Optimizer, and the FinOps Agent preview require. Atlantis autodiscover picks the layer up automatically — no `atlantis.yaml` change needed.

## Architecture

```
┌──────────────────── management account · us-east-1 ────────────────────┐
│                                                                         │
│   OpenTofu (this layer)                    Manual (one-time, preview)   │
│   ─────────────────────                    ─────────────────────────    │
│   aws_iam_role.agent      ──────┐                                       │
│     + agent permissions policy  │          Console wizard →             │
│   aws_iam_role.operator   ──────┼────────► CreateAgentSpace             │
│     + operator perms policy     │          Step 2: "use existing role"  │
│     (trust: finops-agent.       │            → agent_role_arn (output)  │
│      amazonaws.com)             │          Step 3: "use existing role"  │
│                                 └────────►   → operator_role_arn        │
│   aws_ce_anomaly_monitor            ← agent's anomaly-investigation     │
│     (DIMENSIONAL / SERVICE)           feature reads from this           │
│   aws_computeoptimizer_enrollment_status  ← rightsizing recs            │
│     (Active, management only)                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

The agentspace is the only piece with no CFN/tofu/awscc/CDK support, so it is the only manual step. The README carries a "migrate to a native resource when AWS ships support" note.

## Components (files)

| File | Contents |
|---|---|
| `config.tf` | `aws` provider (region/profile from vars); S3 backend key `management/finops-agent/terraform.tfstate`; `aws ~> 5.0`; `required_version ~> 1.6`; `data.aws_caller_identity` + `data.aws_region` |
| `common-variables.tf` | symlink → `../../../config/common-variables.tf` |
| `locals.tf` | standard `tags` (`Terraform`, `Environment`, `Layer`); `name_prefix`; `account_id`; `region`. **No `aws-apn-id` tag** — per CLAUDE.md that PRM tag is scoped to Bedrock Marketplace layers only |
| `variables.tf` | `agent_role_name` (default `FinOpsAgentRole`), `operator_role_name` (default `FinOpsAgentOperatorRole`), `anomaly_monitor_name`, `enable_compute_optimizer` (bool, default `true`) |
| `iam.tf` | two `aws_iam_role` (agent, operator) sharing the trust policy; two customer-managed `aws_iam_policy` built from the documented policy JSON; `aws_iam_role_policy_attachment` for each |
| `cost-anomaly.tf` | `aws_ce_anomaly_monitor` — `DIMENSIONAL` monitor on `SERVICE` |
| `compute-optimizer.tf` | `aws_computeoptimizer_enrollment_status` — `status = "Active"`, `include_member_accounts = false`, gated on `var.enable_compute_optimizer` |
| `outputs.tf` | `agent_role_arn`, `operator_role_arn`, `anomaly_monitor_arn`, `compute_optimizer_status` |
| `README.md` | architecture, OpenTofu-vs-manual split, console-wizard steps (selecting our role ARNs), migration note, and the PRM-tag rationale (why `aws-apn-id` is intentionally absent) |

## Design decision: inline customer-managed policies (not AWS managed)

The two permission policies are implemented as **customer-managed `aws_iam_policy` built from the documented policy JSON**, rather than attaching AWS's managed `FinOpsAgentAgentPolicy` / `FinOpsAgentOperatorPolicy`.

Rationale:
- **Preview service** — managed-policy ARNs may not be reliably attachable yet and may change during preview.
- **Git-visible / versioned** — the exact permission set lives in the repo and is reviewable in PRs.
- **Consistency** — matches the existing inline-`jsonencode` IAM style in `data-science/us-east-1/bedrock-agentcore` and `bedrock-agent-kyb`.

Trade-off: we track AWS's policy revisions manually. The README documents the managed-policy alternative so a future switch is a one-line change.

## Trust policy (verified from AWS docs)

Both roles share this trust policy:

- **Principal:** service `finops-agent.amazonaws.com`
- **Actions:** `sts:AssumeRole`, `sts:SetSourceIdentity` (the latter stamps the calling user's identity onto the session so agent-driven CloudTrail events are attributable per user)
- **Conditions:**
  - `StringEquals` `aws:SourceAccount = <management account id>`
  - `ArnLike` `aws:SourceArn = arn:aws:finops-agent:*:<management account id>:agentspace/*`

The `agentspace/*` wildcard allows any agent in the account to assume the role; after the agentspace is created it can optionally be tightened to the specific agent ID.

## Permission policies (source of truth: AWS docs)

- **Agent permissions policy** (attached to agent role): read access to Cost Explorer (`ce:Get*`/`ce:List*`/`ce:Describe*`), Budgets, Cost Optimization Hub, Compute Optimizer, `ec2/ecs/autoscaling/lambda/rds` describe/list, `organizations` read, `pricing`, `freetier`, `bcm-pricing-calculator`, `cloudtrail` lookup/describe, `cloudwatch` metrics, `logs` query; plus scoped EventBridge management (`events:*` on `rule/*` with `events:ManagedBy = finops-agent.amazonaws.com` and `aws:ResourceAccount` conditions).
- **Operator permissions policy** (attached to operator role): `finops-agent:*` web-application actions (conversations, turns, tasks, automations, documents, artifacts, records, feedback).

Both are reproduced verbatim from the [AWS FinOps Agent IAM setup guide](https://docs.aws.amazon.com/finops-agent/latest/userguide/setting-up.html) in `iam.tf`.

## Manual step (post-apply, one-time)

1. Open the AWS FinOps Agent console in the management account (us-east-1).
2. **Create agent** → name it (e.g. `binbash-finops-agent`).
3. **Step 2 (AWS resources access):** choose **Use an existing role** → select the `agent_role_arn` output.
4. **Step 3 (web app access):** choose **Use an existing role** → select the `operator_role_arn` output.
5. **Step 4 (integrations):** optional Jira/Slack — out of scope for this layer; can be added later.
6. **Create.** Verify both roles appear under **Permissions** on the agent detail page.

## Validation & rollout

1. `leverage tofu fmt -recursive`
2. `leverage tofu validate`
3. `leverage tofu plan` from the layer directory
4. Post the **redacted** plan to the PR per the CLAUDE.md procedure (action section only; 12-digit account IDs → `<MANAGEMENT_ACCOUNT_ID>`; scan clean).
5. **Human applies** after approval — never from automation.
6. Run the manual console wizard (above) selecting the role ARNs.
7. Optional: add an `infracost.yml` entry for completeness (all resources here are $0).

## Out of scope

- The DevOps and Security frontier agents from #1003 (separate specs).
- Jira/Slack integrations (Step 4 of the wizard).
- Org-wide Compute Optimizer enrollment (management-account-only for now; easy future flip via `include_member_accounts`).
- A native IaC resource for the agentspace itself — blocked on AWS shipping CFN/`awscc`/tofu support; tracked in the README migration note.

## Migration note (for the README)

When AWS ships a CloudFormation resource type for the FinOps agentspace (which would also unlock `awscc` and CDK), replace the manual `CreateAgentSpace` step with the native resource, wire it to the existing role ARNs, and import the already-created agentspace into state. Until then, the roles + prerequisites remain fully managed by this layer and only the agentspace is manual.
