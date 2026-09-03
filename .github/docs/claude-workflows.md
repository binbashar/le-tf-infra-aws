# Terraform Plan Workflow

This document describes the **Terraform Plan** GitHub Actions workflow that runs
automated OpenTofu plans with AI-powered analysis on pull requests. It is intended
for contributors who want to understand how automated plan review works.

> Scope: this is the **plan stage**. The apply path and the Claude assistant /
> code-review workflows are delivered in later staged PRs and will be documented
> here as they land.

---

## Overview

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **Terraform Plan** | `terraform-plan.yml` | PR open/update on `*.tf`/`*.tfvars`/`*.hcl`, or `/tofu plan` comment | Auto-plan changed layers, scan for destructive ops, AI analysis |

---

## Workflow: Terraform Plan

**File**: `.github/workflows/terraform-plan.yml`

This is the primary workflow for infrastructure change review. It replaces the
Atlantis/GitOps plan step by combining automated OpenTofu plans with AI analysis.

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant WF as terraform-plan.yml
    participant Tofu as OpenTofu
    participant AI as Claude (ai-analyze-plan)
    participant PR as PR Comment

    Dev->>GH: Push *.tf / *.hcl changes (or comment /tofu plan or /tf-plan)
    GH->>WF: Trigger workflow

    WF->>WF: determine-action<br/>(plan?)
    WF->>WF: detect-layers<br/>(git diff → walk up to nearest config.tf)

    loop For each changed layer (matrix)
        WF->>Tofu: tofu init + tofu plan
        Tofu-->>WF: plan-output.txt (account IDs redacted)
        WF->>GH: Upload artifacts (plan-{layer}/, 7-day retention)
    end

    WF->>WF: scan-destructive-operations<br/>(informational — counts destroy/replace)
    WF->>WF: ai-analyze-plan<br/>Download plan artifacts + capture code diff

    WF->>AI: Claude reads plan outputs + code-diff.txt
    AI->>AI: Analyze WHY (code diff) + WHAT (plan output)
    AI->>AI: Route to specialist agent<br/>(security / cost / layer / feature / deps)
    AI->>PR: Post delta comment + collapsed full-plan dropdown<br/>(default: delta — changed resources only)
```

### Jobs

| Job | Role |
|-----|------|
| `authorize` | Collaborator gate for comment-triggered runs (admin/write only) |
| `eyes-reaction` | 👀 reaction to acknowledge a triggering comment |
| `determine-action` | Decide whether to run a plan (auto PR update, or authorized `/tofu plan` comment) |
| `setup-environment` | Python + dependency cache warm-up |
| `detect-layers` | Marker-based detection — find layer roots (`config.tf`) for changed files |
| `run-terraform-plan` | Per-layer matrix: `setup-layer-context` → `tofu init` → `tofu plan` → upload artifact |
| `scan-destructive-operations` | Count `destroy`/`replace` and post an informational warning |
| `ai-analyze-plan` | Claude reads plan + code diff and posts the PR comment |

`run-terraform-plan` uses the **`setup-layer-context`** composite action, which
consolidates the repeated OpenTofu/Leverage install, account resolution, AWS
credentials, and reference-architecture config into a single step.

### Key Features
- **Single comment format**: PR comments show only changed resources (`+`, `~`, `-`, `-/+`) plus a meaningful one-sentence summary, with a collapsed dropdown carrying the full plan. There is no separate "full" command or mode — see the design-decision note in [`output-formats.md`](../../.claude/docs/output-formats.md).
- **Complete plan retained**: every run uploads the full `plan-output.txt` as the `plan-<layer>` artifact (7-day retention) — the authoritative, never-truncated copy. No `tfplan.bin` in the plan stage: a saved binary plan embeds raw state values, and artifacts on this public repo are downloadable by anyone (the apply stage reintroduces it behind its own protections).
- **Sensitive-identifier redaction**: plan output is redacted at the source (AWS account IDs → `<ACCOUNT_ID_REDACTED>`, access-key IDs → `***`) before the artifact upload, the destructive-op scan, and the AI comment ever see it — per the repo policy of never exposing account IDs in PRs.
- **Short alias**: `/tf-plan` = `/tofu plan`.
- **Code diff context**: Claude reads `.tf`/`.hcl` changes alongside the plan to understand developer intent.
- **Destructive-op scan**: destroy/replace counts are surfaced for reviewer attention (informational — the plan stage does not apply).
- **Concurrency guard**: one plan runs per PR at a time (`cancel-in-progress: false`).

Output formatting is defined once in [`.claude/docs/output-formats.md`](../../.claude/docs/output-formats.md) and referenced by both the workflow's AI step and the local `/tf-plan` skills.

---

## Agent Integration Map

The `ai-analyze-plan` step routes to specialized agents for deep domain expertise,
based on file paths, layer names, resource types, and request keywords (see
[`.claude/docs/agent-guide.md`](../../.claude/docs/agent-guide.md)).

| Agent | Trigger Patterns | Capabilities |
|-------|-----------------|--------------|
| **security-compliance** | `security-*`, `secrets-manager`, `iam`, `kms`, `audit`, `compliance` | IAM policy analysis, encryption review, CIS compliance, least privilege |
| **cost-optimization** | `cost`, `infracost`, `billing`, resource sizing, `spot`, `reserved` | Infracost analysis, tagging strategy, right-sizing recommendations |
| **terraform-layer** | General `.tf` changes, `base-network`, `databases-*`, `k8s-*` | Layer creation/modification, init/plan, state management |
| **feature-implementation** | New layers, new services, `feature`, `add`, new `aws_*` resources | New service integration, multi-account patterns, reference architectures |
| **issue-fix** | `fix`, `bug`, `error`, `failed`, troubleshooting, CI failures | Root cause analysis, debugging, error resolution |
| **documentation** | `.md`, `README`, `DEPLOYMENT.md`, `docs/` | Layer docs, Mermaid diagrams, CLAUDE.md maintenance |
| **dependency-update** | Renovate PRs, `provider`, `module`, version constraints | Version bump reviews, compatibility checks, lock file updates |

---

## Command Reference

### Local Claude Code IDE (slash commands)

| Command | Description | Output |
|---------|-------------|--------|
| `/tf-plan` | Delta plan for current layer | Changed resources only + meaningful summary |

Run from a Terraform layer directory (one containing `config.tf`):
```bash
cd apps-devstg/us-east-1/secrets-manager
/tf-plan            # See what will change (delta + summary)
leverage tf plan    # See the complete, unfiltered output
```

### PR Comment Commands

| Command | Alias | Required GitHub Role | Behavior |
|---------|-------|----------------------|----------|
| `/tofu plan` | `/tf-plan` | Collaborator with admin/write access | Plan via the Terraform Plan workflow (delta comment + collapsed full-plan dropdown + artifact) |

Automatic plans run on every PR that changes `*.tf` / `*.tfvars` / `*.hcl` (non-fork).
