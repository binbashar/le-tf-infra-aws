# AWS FinOps Agent (management layer) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a new OpenTofu layer `management/global/finops-agent` that provisions everything the AWS FinOps Agent (preview) needs that is IaC-able — two IAM roles with inline permission policies, a Cost Anomaly Detection monitor, and Compute Optimizer opt-in for the management account — leaving only the preview-only `CreateAgentSpace` as a documented manual step.

**Architecture:** A standard Leverage global layer in the management (payer) account, us-east-1. The FinOps Agent agentspace has no CloudFormation/`awscc`/CDK/tofu resource (preview API only), so the layer creates the two roles the service assumes (`finops-agent.amazonaws.com` trust) plus feature prerequisites, and the one-time agentspace creation selects those roles via the console wizard's "use an existing role" option.

**Tech Stack:** OpenTofu (Leverage CLI wrapper), `hashicorp/aws ~> 5.0` provider, S3 backend with DynamoDB locking.

**Spec:** `docs/superpowers/specs/2026-07-17-finops-agent-mgmt-design.md`

---

## Testing model (read first)

This is a **layer**, not a reusable module, so there is no `tofu test` unit surface. Verification is layered:

- **Per-task gate (no AWS credentials needed):** `leverage tofu fmt` + offline `tofu validate` (via `tofu init -backend=false`). This catches HCL syntax errors, undefined references, wrong provider argument names, and type mismatches against the provider schema.
- **Integration verification (needs AWS SSO, final task):** `leverage tofu init` + `leverage tofu plan`. This is the real "does it plan cleanly against AWS" test.
- **Behavioral smoke (manual, post-apply):** create the agentspace in the console selecting the role outputs, confirm both roles appear under **Permissions**.

The offline validate uses the **native `tofu`** binary directly (not the `leverage` wrapper, which forces a backend init requiring SSO). Per the repo's Apple Silicon note, ensure `file $(which tofu)` reports `arm64` — an x86_64 tofu under Rosetta can hang on AWS provider schema loads. `aws ~> 5.0` is used (not 6.x) and is known-good.

## File structure

| File | Responsibility |
|---|---|
| `management/global/finops-agent/config.tf` | Provider, S3 backend key, provider version pins, data sources (`aws_caller_identity`, `aws_region`) |
| `management/global/finops-agent/common-variables.tf` | Symlink → `../../../config/common-variables.tf` (shared variable definitions + `local.layer_name`) |
| `management/global/finops-agent/variables.tf` | Layer-specific inputs (role names, monitor name, Compute Optimizer toggle) |
| `management/global/finops-agent/locals.tf` | Standard `tags`, `account_id`, `region` |
| `management/global/finops-agent/iam.tf` | Shared trust policy local; agent + operator roles; inline customer-managed policies; attachments |
| `management/global/finops-agent/cost-anomaly.tf` | `aws_ce_anomaly_monitor` (DIMENSIONAL / SERVICE) |
| `management/global/finops-agent/compute-optimizer.tf` | `aws_computeoptimizer_enrollment_status` (management account only, gated) |
| `management/global/finops-agent/outputs.tf` | Role ARNs, monitor ARN, Compute Optimizer status |
| `management/global/finops-agent/README.md` | Architecture, tofu-vs-manual split, wizard steps, migration note, PRM-tag rationale |
| `management/global/finops-agent/CLAUDE.md` | Layer-scoped agent guidance |

No per-layer `.gitignore` — the repo root `.gitignore` already excludes `.terraform/` and `tfplan` for all 100+ layers.

---

## Task 1: Scaffold a validatable layer skeleton

**Files:**
- Create: `management/global/finops-agent/config.tf`
- Create: `management/global/finops-agent/common-variables.tf` (symlink)
- Create: `management/global/finops-agent/variables.tf`
- Create: `management/global/finops-agent/locals.tf`

- [ ] **Step 1: Create the layer directory and the symlink**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
mkdir -p management/global/finops-agent
ln -s ../../../config/common-variables.tf management/global/finops-agent/common-variables.tf
# Verify the symlink resolves:
test -f management/global/finops-agent/common-variables.tf && echo "symlink OK"
```

Expected: `symlink OK`

- [ ] **Step 2: Write `config.tf`**

```hcl
#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key = "management/finops-agent/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
```

- [ ] **Step 3: Write `variables.tf`**

```hcl
variable "agent_role_name" {
  description = "Name of the IAM role the FinOps Agent service assumes to read cost and operational data (wizard Step 2)."
  type        = string
  default     = "FinOpsAgentRole"
}

variable "operator_role_name" {
  description = "Name of the IAM role the FinOps Agent web app assumes for operator actions (wizard Step 3)."
  type        = string
  default     = "FinOpsAgentOperatorRole"
}

variable "anomaly_monitor_name" {
  description = "Name of the Cost Anomaly Detection monitor the agent investigates."
  type        = string
  default     = "finops-agent-service-monitor"
}

variable "enable_compute_optimizer" {
  description = "Opt the management account in to AWS Compute Optimizer (management account only; does not enroll member accounts)."
  type        = bool
  default     = true
}
```

- [ ] **Step 4: Write `locals.tf`**

`local.layer_name` is provided by the symlinked `common-variables.tf` (auto-detected from `path.cwd` → resolves to `finops-agent`). `data.aws_region.current.name` is correct for the aws provider v5 (v6 renamed it to `.region`).

```hcl
locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}
```

- [ ] **Step 5: Format**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
.venv/bin/leverage tofu fmt management/global/finops-agent
```

Expected: no output, or the filenames it reformatted. Exit 0.

- [ ] **Step 6: Offline validate (installs providers, no AWS creds)**

```bash
cd management/global/finops-agent
file "$(command -v tofu)"        # expect: ... arm64  (Rosetta x86 can hang on aws schema load)
tofu init -backend=false -input=false
tofu validate
```

Expected: `Success! The configuration is valid.`

If `tofu init` reports "Backend initialization required" despite `-backend=false`, remove any stale `.terraform` dir (`rm -rf .terraform`) and retry.

- [ ] **Step 7: Commit**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
git add management/global/finops-agent/config.tf \
        management/global/finops-agent/common-variables.tf \
        management/global/finops-agent/variables.tf \
        management/global/finops-agent/locals.tf
git commit -m "feat(finops-agent): scaffold management/global/finops-agent layer"
```

---

## Task 2: IAM roles + inline permission policies

**Files:**
- Create: `management/global/finops-agent/iam.tf`

The two policies are reproduced **verbatim** from the [AWS FinOps Agent IAM setup guide](https://docs.aws.amazon.com/finops-agent/latest/userguide/setting-up.html) (Policy 2 = agent, Policy 3 = operator). The trust policy is Policy shared trust from the same page.

> **Critical HCL escaping:** the EventBridge conditions use the IAM policy variable `${aws:PrincipalAccount}`. Inside a Terraform `jsonencode` string, `${` starts interpolation, so it MUST be escaped as `$${aws:PrincipalAccount}` to emit the literal IAM variable. Do not change it to `local.account_id` — the AWS policy intentionally uses the runtime principal's account.

- [ ] **Step 1: Write `iam.tf`**

```hcl
#=============================#
# Shared trust policy         #
#=============================#
locals {
  # Both roles are assumed by the FinOps Agent service. SetSourceIdentity stamps the
  # calling user's identity onto the session so agent-driven CloudTrail events are
  # attributable per user. SourceArn is scoped to any agentspace in this account;
  # tighten to a specific agent ID after CreateAgentSpace if desired.
  finops_agent_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "finops-agent.amazonaws.com" }
        Action    = ["sts:AssumeRole", "sts:SetSourceIdentity"]
        Condition = {
          StringEquals = { "aws:SourceAccount" = local.account_id }
          ArnLike      = { "aws:SourceArn" = "arn:aws:finops-agent:*:${local.account_id}:agentspace/*" }
        }
      }
    ]
  })
}

#=============================#
# Agent role (data access)    #
#=============================#
resource "aws_iam_role" "agent" {
  name               = var.agent_role_name
  assume_role_policy = local.finops_agent_trust_policy
  tags               = local.tags
}

resource "aws_iam_policy" "agent" {
  name        = "${var.agent_role_name}Policy"
  description = "FinOps Agent data-access permissions (Cost Explorer, Compute Optimizer, pricing, EventBridge managed rules). Mirrors AWS managed FinOpsAgentAgentPolicy; kept inline for preview-stability and git visibility."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FinOpsAgentDataAccess"
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetCostAndUsageWithResources",
          "ce:GetCostForecast",
          "ce:GetUsageForecast",
          "ce:GetDimensionValues",
          "ce:GetTags",
          "ce:GetCostCategories",
          "ce:GetCostAndUsageComparisons",
          "ce:GetCostComparisonDrivers",
          "ce:GetSavingsPlansCoverage",
          "ce:GetSavingsPlansUtilization",
          "ce:GetSavingsPlansUtilizationDetails",
          "ce:GetSavingsPlansPurchaseRecommendation",
          "ce:GetReservationCoverage",
          "ce:GetReservationUtilization",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetAnomalies",
          "ce:GetAnomalyMonitors",
          "ce:ListCostAllocationTags",
          "ce:ListCostAllocationTagBackfillHistory",
          "ce:DescribeCostCategoryDefinition",
          "ce:ListCostCategoryDefinitions",
          "budgets:ViewBudget",
          "cost-optimization-hub:GetRecommendation",
          "cost-optimization-hub:ListRecommendations",
          "cost-optimization-hub:ListRecommendationSummaries",
          "compute-optimizer:DescribeRecommendationExportJobs",
          "compute-optimizer:GetEnrollmentStatus",
          "compute-optimizer:GetEnrollmentStatusesForOrganization",
          "compute-optimizer:GetRecommendationSummaries",
          "compute-optimizer:GetEC2InstanceRecommendations",
          "compute-optimizer:GetEC2RecommendationProjectedMetrics",
          "compute-optimizer:GetAutoScalingGroupRecommendations",
          "compute-optimizer:GetEBSVolumeRecommendations",
          "compute-optimizer:GetLambdaFunctionRecommendations",
          "compute-optimizer:GetRecommendationPreferences",
          "compute-optimizer:GetEffectiveRecommendationPreferences",
          "compute-optimizer:GetECSServiceRecommendations",
          "compute-optimizer:GetECSServiceRecommendationProjectedMetrics",
          "compute-optimizer:GetLicenseRecommendations",
          "compute-optimizer:GetRDSDatabaseRecommendations",
          "compute-optimizer:GetRDSDatabaseRecommendationProjectedMetrics",
          "compute-optimizer:GetIdleRecommendations",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ecs:ListServices",
          "ecs:ListClusters",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "lambda:ListFunctions",
          "lambda:ListProvisionedConcurrencyConfigs",
          "organizations:ListAccounts",
          "organizations:DescribeOrganization",
          "organizations:DescribeAccount",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "pricing:DescribeServices",
          "pricing:GetAttributeValues",
          "pricing:GetProducts",
          "freetier:GetFreeTierUsage",
          "bcm-pricing-calculator:GetPreferences",
          "bcm-pricing-calculator:GetWorkloadEstimate",
          "bcm-pricing-calculator:ListWorkloadEstimateUsage",
          "bcm-pricing-calculator:ListWorkloadEstimates",
          "cloudtrail:LookupEvents",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:GetEventSelectors",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:StartQuery",
          "logs:GetQueryResults",
        ]
        Resource = "*"
      },
      {
        Sid    = "EventBridgeManagedRuleManagementWritePermissions"
        Effect = "Allow"
        Action = [
          "events:PutRule",
          "events:PutTargets",
          "events:DeleteRule",
          "events:RemoveTargets",
          "events:EnableRule",
          "events:DisableRule",
        ]
        Resource = "arn:aws:events:*:*:rule/*"
        Condition = {
          StringEquals = {
            "events:ManagedBy"    = "finops-agent.amazonaws.com"
            "aws:ResourceAccount" = "$${aws:PrincipalAccount}"
          }
        }
      },
      {
        Sid    = "EventBridgeManagedRuleManagementReadPermissions"
        Effect = "Allow"
        Action = [
          "events:DescribeRule",
          "events:ListTargetsByRule",
        ]
        Resource = "arn:aws:events:*:*:rule/*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = "$${aws:PrincipalAccount}"
          }
        }
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "agent" {
  role       = aws_iam_role.agent.name
  policy_arn = aws_iam_policy.agent.arn
}

#=============================#
# Operator role (web app)     #
#=============================#
resource "aws_iam_role" "operator" {
  name               = var.operator_role_name
  assume_role_policy = local.finops_agent_trust_policy
  tags               = local.tags
}

resource "aws_iam_policy" "operator" {
  name        = "${var.operator_role_name}Policy"
  description = "FinOps Agent web-app operator permissions (conversations, tasks, automations, documents). Mirrors AWS managed FinOpsAgentOperatorPolicy; kept inline for preview-stability and git visibility."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FinOpsAgentOperatorAccess"
        Effect = "Allow"
        Action = [
          "finops-agent:CreateConversation",
          "finops-agent:ListConversations",
          "finops-agent:CreateTurn",
          "finops-agent:GetTurn",
          "finops-agent:ListTurns",
          "finops-agent:CancelTurn",
          "finops-agent:AcceptAgentRequest",
          "finops-agent:RejectAgentRequest",
          "finops-agent:GetAgentRequest",
          "finops-agent:CreateTask",
          "finops-agent:GetTask",
          "finops-agent:ListTasks",
          "finops-agent:CancelTask",
          "finops-agent:CreateAutomation",
          "finops-agent:GetAutomation",
          "finops-agent:ListAutomations",
          "finops-agent:UpdateAutomation",
          "finops-agent:DeleteAutomation",
          "finops-agent:CreateDocument",
          "finops-agent:GetDocumentContent",
          "finops-agent:GetDocumentMetadata",
          "finops-agent:ListDocuments",
          "finops-agent:UpdateDocument",
          "finops-agent:DeleteDocument",
          "finops-agent:RestoreDocument",
          "finops-agent:DeleteArtifact",
          "finops-agent:GetArtifactContent",
          "finops-agent:GetArtifactMetadata",
          "finops-agent:ListArtifacts",
          "finops-agent:ListRecords",
          "finops-agent:SendFeedback",
        ]
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "operator" {
  role       = aws_iam_role.operator.name
  policy_arn = aws_iam_policy.operator.arn
}
```

- [ ] **Step 2: Format**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
.venv/bin/leverage tofu fmt management/global/finops-agent
```

Expected: exit 0.

- [ ] **Step 3: Offline validate**

```bash
cd management/global/finops-agent
tofu validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 4: Verify the `${aws:PrincipalAccount}` literal survived (not interpolated to empty)**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
grep -c 'aws:PrincipalAccount' management/global/finops-agent/iam.tf
```

Expected: `2` (both EventBridge statements). If validate had interpolated it, validate itself would have errored on the unknown reference `aws:PrincipalAccount`.

- [ ] **Step 5: Commit**

```bash
git add management/global/finops-agent/iam.tf
git commit -m "feat(finops-agent): add agent and operator IAM roles with inline policies"
```

---

## Task 3: Cost Anomaly Detection monitor

**Files:**
- Create: `management/global/finops-agent/cost-anomaly.tf`

A `DIMENSIONAL` monitor on the `SERVICE` dimension — the AWS-services monitor the agent investigates. `monitor_dimension` is ForceNew in the provider (changing it replaces the monitor); `SERVICE` is the only valid dimension for a `DIMENSIONAL` monitor.

- [ ] **Step 1: Write `cost-anomaly.tf`**

```hcl
#=============================#
# Cost Anomaly Detection      #
#=============================#
# Enables the FinOps Agent's headline anomaly-investigation feature. The agent reads
# anomalies produced by this monitor via ce:GetAnomalies / ce:GetAnomalyMonitors.
resource "aws_ce_anomaly_monitor" "service" {
  name              = var.anomaly_monitor_name
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = local.tags
}
```

- [ ] **Step 2: Format + validate**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
.venv/bin/leverage tofu fmt management/global/finops-agent
cd management/global/finops-agent && tofu validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 3: Commit**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
git add management/global/finops-agent/cost-anomaly.tf
git commit -m "feat(finops-agent): add SERVICE cost anomaly monitor"
```

---

## Task 4: Compute Optimizer opt-in

**Files:**
- Create: `management/global/finops-agent/compute-optimizer.tf`

Scoped to the management account only (`include_member_accounts = false`) per the spec. Gated behind `var.enable_compute_optimizer` so it can be turned off without deleting the file. This resource does **not** accept a `tags` argument.

- [ ] **Step 1: Write `compute-optimizer.tf`**

```hcl
#=============================#
# Compute Optimizer opt-in    #
#=============================#
# Enables rightsizing / idle-resource recommendations for the FinOps Agent. Scoped to
# the management account only; flip include_member_accounts (and enable Organizations
# trusted access) to enroll the whole org later.
resource "aws_computeoptimizer_enrollment_status" "this" {
  count = var.enable_compute_optimizer ? 1 : 0

  status                  = "Active"
  include_member_accounts = false
}
```

- [ ] **Step 2: Format + validate**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
.venv/bin/leverage tofu fmt management/global/finops-agent
cd management/global/finops-agent && tofu validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 3: Commit**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
git add management/global/finops-agent/compute-optimizer.tf
git commit -m "feat(finops-agent): opt management account in to Compute Optimizer"
```

---

## Task 5: Outputs

**Files:**
- Create: `management/global/finops-agent/outputs.tf`

The role ARNs are what the operator selects in the console wizard (Steps 2 and 3). The Compute Optimizer output handles the gated `count` safely.

- [ ] **Step 1: Write `outputs.tf`**

```hcl
output "agent_role_arn" {
  description = "ARN of the FinOps Agent data-access role. Select this in wizard Step 2 (AWS resources access)."
  value       = aws_iam_role.agent.arn
}

output "operator_role_arn" {
  description = "ARN of the FinOps Agent operator role. Select this in wizard Step 3 (web app access)."
  value       = aws_iam_role.operator.arn
}

output "anomaly_monitor_arn" {
  description = "ARN of the Cost Anomaly Detection monitor the agent investigates."
  value       = aws_ce_anomaly_monitor.service.arn
}

output "compute_optimizer_status" {
  description = "Compute Optimizer enrollment status for the management account."
  value       = var.enable_compute_optimizer ? aws_computeoptimizer_enrollment_status.this[0].status : "Inactive (not managed by this layer)"
}
```

- [ ] **Step 2: Format + validate**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
.venv/bin/leverage tofu fmt management/global/finops-agent
cd management/global/finops-agent && tofu validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 3: Commit**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
git add management/global/finops-agent/outputs.tf
git commit -m "feat(finops-agent): expose role ARNs and prerequisite outputs"
```

---

## Task 6: Documentation (README + layer CLAUDE.md)

**Files:**
- Create: `management/global/finops-agent/README.md`
- Create: `management/global/finops-agent/CLAUDE.md`

- [ ] **Step 1: Write `README.md`**

````markdown
# FinOps Agent (management account)

Provisions the IaC-able foundation for the [AWS FinOps Agent](https://aws.amazon.com/finops-agent/) (preview) in the management (payer) account, us-east-1.

## What this layer manages vs. what is manual

The FinOps Agent **agentspace** is created only through a preview API (`finops-agent:CreateAgentSpace`). There is **no CloudFormation resource type** for it, and because CDK and the Terraform `awscc` provider are both generated from the CloudFormation registry, **neither CDK nor awscc can create it either**. The plain `hashicorp/aws` provider has no `aws_finops*` resource. So CDK offers no advantage over OpenTofu here.

This layer therefore manages everything that *is* IaC-able, and the agentspace is the single documented manual step.

```
┌──────────────────── management account · us-east-1 ────────────────────┐
│   OpenTofu (this layer)                    Manual (one-time, preview)   │
│   ─────────────────────                    ─────────────────────────    │
│   aws_iam_role.agent      ──────┐          Console wizard →             │
│     + agent policy              ├────────► CreateAgentSpace             │
│   aws_iam_role.operator   ──────┤          Step 2: use existing role    │
│     + operator policy           │            → agent_role_arn           │
│   (trust: finops-agent.         └────────► Step 3: use existing role    │
│    amazonaws.com)                            → operator_role_arn        │
│   aws_ce_anomaly_monitor            ← anomaly-investigation feature     │
│   aws_computeoptimizer_enrollment_status  ← rightsizing recs (mgmt)     │
└─────────────────────────────────────────────────────────────────────────┘
```

## Deploy

```bash
cd management/global/finops-agent
leverage tofu init
leverage tofu plan
leverage tofu apply   # human step, after PR approval
```

## Create the agentspace (one-time, manual)

1. Open the AWS FinOps Agent console in the management account (us-east-1).
2. **Create agent** → name it (e.g. `binbash-finops-agent`).
3. **Step 2 (AWS resources access):** choose **Use an existing role** → paste the `agent_role_arn` output.
4. **Step 3 (web app access):** choose **Use an existing role** → paste the `operator_role_arn` output.
5. **Step 4 (integrations):** optional Jira/Slack — not managed here.
6. **Create.** Confirm both roles appear under **Permissions** on the agent detail page.

Get the ARNs:

```bash
leverage tofu output agent_role_arn
leverage tofu output operator_role_arn
```

## Permission policies

The agent and operator policies are kept **inline** (customer-managed `aws_iam_policy`) rather than attaching AWS's managed `FinOpsAgentAgentPolicy` / `FinOpsAgentOperatorPolicy`, because the service is in preview (managed-policy ARNs may change or not be attachable yet) and inline keeps the exact permission set git-visible. They mirror the [AWS IAM setup guide](https://docs.aws.amazon.com/finops-agent/latest/userguide/setting-up.html) verbatim. To switch to the managed policies later, replace each `aws_iam_policy` + attachment pair with an `aws_iam_role_policy_attachment` referencing the managed ARN.

## Why no `aws-apn-id` tag

Per the repo `CLAUDE.md`, the `aws-apn-id` PRM tag is reserved for specific Bedrock AWS Marketplace layers and must not be added elsewhere without Partner Development Manager approval. This layer intentionally omits it.

## Migration note

When AWS ships a CloudFormation resource type for the agentspace (which would also unlock `awscc` and CDK), replace the manual `CreateAgentSpace` step with the native resource, wire it to the existing role ARNs, and `import` the already-created agentspace into state. Until then, roles + prerequisites are fully managed here and only the agentspace is manual.
````

- [ ] **Step 2: Write `CLAUDE.md`**

```markdown
# CLAUDE.md

Guidance for Claude Code when working in this layer.

## Layer Overview

Provisions the IaC-able foundation for the AWS FinOps Agent (preview) in the management account: two IAM roles (`finops-agent.amazonaws.com` trust), inline permission policies mirroring the AWS setup guide, a SERVICE cost anomaly monitor, and Compute Optimizer opt-in (management account only). The agentspace itself is created manually via the console wizard (preview API only — no CFN/awscc/CDK/tofu resource exists).

## Gotchas

- **`${aws:PrincipalAccount}` must be escaped as `$${aws:PrincipalAccount}`** inside the `jsonencode` policy blocks in `iam.tf` — it is an IAM policy variable, not a Terraform reference.
- **Inline vs managed policies:** policies are intentionally inline (preview stability + git visibility). See README for the managed-policy switch.
- **Provider `aws ~> 5.0`**, not 6.x (see repo CLAUDE.md re: Apple Silicon Rosetta hang on 6.x). Both `aws_ce_anomaly_monitor` and `aws_computeoptimizer_enrollment_status` exist in 5.100.
- **`aws_computeoptimizer_enrollment_status` takes no `tags`** and is gated behind `var.enable_compute_optimizer`.
- **Offline validate:** `tofu init -backend=false && tofu validate` (native tofu, no SSO). Full `leverage tofu plan` needs SSO.

## Manual post-apply step

Create the agentspace in the console selecting the `agent_role_arn` (Step 2) and `operator_role_arn` (Step 3) outputs. See README.
```

- [ ] **Step 3: Commit**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
git add management/global/finops-agent/README.md management/global/finops-agent/CLAUDE.md
git commit -m "docs(finops-agent): add layer README and CLAUDE.md"
```

---

## Task 7: Cost analysis entry (Infracost)

**Files:**
- Modify: `infracost.yml`

All resources in this layer are $0 (IAM, a cost monitor, a Compute Optimizer opt-in), but every layer has an `infracost.yml` entry for consistency and so the PR cost workflow does not report a missing path.

- [ ] **Step 1: Find where management layers are listed**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
grep -n "management/global/cost-mgmt\|management/global/cost-report" infracost.yml
```

Expected: one or more line numbers showing the existing `path:` entry format for management global layers.

- [ ] **Step 2: Add the entry, matching the exact surrounding format**

Insert a new `- path: management/global/finops-agent` entry adjacent to the other `management/global/*` entries, copying the exact key/indentation style of the neighbor shown in Step 1 (entries in this file are typically just `- path: <layer>`).

```yaml
  - path: management/global/finops-agent
```

- [ ] **Step 3: Validate YAML**

```bash
python3 -c "import yaml,sys; yaml.safe_load(open('infracost.yml')); print('infracost.yml OK')"
```

Expected: `infracost.yml OK`

- [ ] **Step 4: Commit**

```bash
git add infracost.yml
git commit -m "chore(finops-agent): add infracost entry for the new layer"
```

---

## Task 8: Integration verification + PR (needs AWS SSO — human/interactive)

This task cannot run in a credential-less subagent. It requires `leverage aws sso login` (interactive browser).

- [ ] **Step 1: Authenticate**

```bash
# User runs this (interactive):
leverage aws sso login
```

- [ ] **Step 2: Real init + plan**

```bash
cd management/global/finops-agent
.venv/bin/leverage tofu init
.venv/bin/leverage tofu plan -no-color > /tmp/finops-plan.txt 2>&1
tail -30 /tmp/finops-plan.txt
```

Expected: a clean plan ending with roughly `Plan: 6 to add, 0 to change, 0 to destroy.` (2 roles + 2 policies + 2 attachments + 1 monitor + up to 1 Compute Optimizer enrollment; exact count may differ by a few). No errors.

- [ ] **Step 3: Extract + redact the plan for the PR (per repo CLAUDE.md)**

```bash
awk '/will perform the following actions/{f=1} f' /tmp/finops-plan.txt > /tmp/finops-plan-clean.txt
sed -E 's/[0-9]{12}/<MANAGEMENT_ACCOUNT_ID>/g; s/(AKIA|ASIA)[A-Z0-9]{16}/***/g' /tmp/finops-plan-clean.txt > /tmp/finops-plan-redacted.txt
grep -nE '[0-9]{12}|arn:aws:iam::[0-9]|AKIA|ASIA|-----BEGIN' /tmp/finops-plan-redacted.txt   # expect NO output
```

Expected: the `grep` prints nothing.

- [ ] **Step 4: Push and open the PR**

```bash
cd /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws
git push -u origin feat/finops-agent-mgmt
```

Open a PR to `master` using the What / Why / References template, embedding `/tmp/finops-plan-redacted.txt` inside a collapsible `<details>` block with a ```` ```text ```` fence. Reference issue #1003 (FinOps portion). **Do not apply or merge from automation** — a human applies after approval.

- [ ] **Step 5: Human apply (after PR approval)**

```bash
cd management/global/finops-agent
.venv/bin/leverage tofu apply
```

- [ ] **Step 6: Behavioral smoke — create the agentspace**

Follow the README "Create the agentspace" steps, selecting the `agent_role_arn` and `operator_role_arn` outputs. Confirm both roles list under **Permissions** on the agent detail page, and open the web app to confirm it loads.

---

## Self-review notes

- **Spec coverage:** IAM roles + inline policies (Task 2) ✓; anomaly monitor (Task 3) ✓; Compute Optimizer mgmt-only (Task 4) ✓; outputs incl. role ARNs (Task 5) ✓; README with tofu-vs-manual split, wizard steps, migration note, PRM-tag rationale (Task 6) ✓; validation & redacted-plan rollout (Task 8) ✓; Infracost entry (Task 7, spec "optional") ✓.
- **No agentspace resource** is created in any task — matches the spec's core finding.
- **Type/name consistency:** `aws_iam_role.agent` / `.operator`, `aws_ce_anomaly_monitor.service`, `aws_computeoptimizer_enrollment_status.this` used identically in `outputs.tf` and the plan output expectation. Variable names (`enable_compute_optimizer`, `anomaly_monitor_name`) consistent across `variables.tf`, `compute-optimizer.tf`, `cost-anomaly.tf`, `outputs.tf`.
- **Escaping caveat** for `$${aws:PrincipalAccount}` is called out where it matters (Task 2) and re-stated in the layer CLAUDE.md.
```
