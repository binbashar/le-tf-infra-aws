---
description: "Analyze Terraform plan outputs and post PR comment with AI-powered routing"
allowed-tools: ["Task", "Read", "Grep", "Glob", "Bash(gh pr comment:*)", "Bash(gh pr view:*)", "Bash(gh pr diff:*)", "Bash(gh issue view:*)", "Bash(gh issue list:*)"]
---

# Terraform Plan Analysis

Analyze plan outputs in `plans/` and post a structured PR comment.

## Workflow

1. Read `plans/code-diff.txt` to understand developer intent (the WHY)
2. Read plan outputs from `plans/` (`plan-output.txt` files in per-layer subdirectories — the WHAT)
3. Identify resources created (+), modified (~), destroyed (-), replaced (-/+) per layer
4. Route to a specialized agent via the Task tool based on resource types (see `.claude/docs/agent-guide.md`)

## Output format

Follow `.claude/docs/output-formats.md` exactly — it is the single source of
truth for the plan-comment format and structure. Do not re-invent the format here.

Every comment uses the same layout (there is no separate "full" mode — see the
design-decision note in `output-formats.md`):
- Summary + changed resources only + `Plan: X to add, …` + assessment.
- A **collapsed `<details>` "Full plan output"** dropdown. The embedded text comes
  from each layer's `plans/<artifact>/plan-output.txt`. **Cap it at ~60,000
  characters** (GitHub's comment limit is 65,536); when you truncate, say so and
  point to the artifact.
- End with the artifact pointer: the complete plan is in the **`plan-<layer>`**
  artifact (7-day retention).
- If `DestructionCount > 0`, explicitly call out the destroy/replace resources in
  the assessment.

## Agent Responsibilities

The delegated agent MUST post the PR comment via `gh pr comment <PR_NUMBER> --body '...'`.
