---
description: "Analyze Terraform plan outputs and post PR comment with AI-powered routing"
allowed-tools: ["Task", "Read", "Grep", "Glob", "Bash(gh pr comment:*)", "Bash(gh pr view:*)", "Bash(gh pr diff:*)", "Bash(gh issue view:*)", "Bash(gh issue list:*)"]
---

# Terraform Plan Analysis

Analyze plan outputs in `plans/` and post structured PR comment.

## Workflow

1. Read `plans/code-diff.txt` to understand developer intent
2. Read plan outputs from `plans/` (plan-output.txt files in subdirectories)
3. Identify resources created (+), modified (~), destroyed (-) per layer
4. Route to specialized agent via Task tool based on resource types (see `.claude/docs/agent-guide.md`)

## Agent Responsibilities

The delegated agent MUST post a PR comment via `gh pr comment <PR_NUMBER> --body '...'`.

### DELTA format (default)
- One-sentence summary of what the changes accomplish (from code diff intent)
- Only changed resource blocks with `+`/`~`/`-` notation
- Standard plan line: `Plan: X to add, X to change, X to destroy`
- Security/cost/risk assessment

### FULL format
- Summary line and assessment
- Complete plan output in a collapsible `<details>` block

If destructive operations were detected (DestructionCount > 0), highlight them in the assessment.
