---
description: "Context-only PR code review with intelligent agent routing"
allowed-tools: ["Task", "Read", "Grep", "Glob", "Bash(gh pr comment:*)", "Bash(gh pr view:*)", "Bash(gh issue view:*)", "Bash(gh issue list:*)"]
---

# PR Code Review

Context-only analysis of changed files — no Terraform execution involved.

## Workflow

1. Read `changed-files.txt` and `file-diffs.txt`
2. Identify change types, affected AWS services, and security implications
3. Route to specialized agent via Task tool (see `.claude/docs/agent-guide.md`)
   - SSO/IAM changes -> `security-compliance`
   - Documentation -> `documentation`
   - Module updates -> `dependency-update`
   - General infra -> `terraform-layer`

## Agent Output

The agent posts a PR comment via `gh pr comment <PR_NUMBER> --body '...'` with:
- Summary (2-3 sentences)
- Critical issues (if any)
- Warnings (if any)
- Suggestions for improvement
- Recommendation: APPROVE / REQUEST_CHANGES / COMMENT
