---
description: "Route CI requests to specialized agents via intelligent analysis"
allowed-tools: ["Task", "Read", "Grep", "Glob", "Bash(gh issue view:*)", "Bash(gh search:*)", "Bash(gh issue list:*)", "Bash(gh pr comment:*)", "Bash(gh pr diff:*)", "Bash(gh pr view:*)", "Bash(gh pr list:*)", "Bash(gh api:*)", "Bash(git:*)", "Bash(find:*)", "Bash(grep:*)", "Bash(cat:*)", "Bash(ls:*)"]
---

# CI Request Router

Route incoming requests to specialized agents. Check for special terraform commands first, then analyze context for intelligent routing.

## Special Commands (check first)

### `@claude tf-plan` (not `tf-plan full`)
Post `/terraform plan` as a PR comment via `gh pr comment <PR> --body "/terraform plan"` and confirm.

### `@claude tf-plan full`
Post `/terraform plan full` as a PR comment and confirm.

### `@claude tf-apply`
1. Check commenter permission: `gh api repos/{owner}/{repo}/collaborators/{username}/permission --jq '.permission'`
2. Deny if not admin/write
3. If authorized, post `/terraform apply` as a PR comment and confirm

## Intelligent Routing (if not a special command)

Analyze file paths, layer types, and keywords, then delegate via the Task tool.
Read `.claude/docs/agent-guide.md` for agent selection criteria.

Available agents: `security-compliance`, `cost-optimization`, `terraform-layer`, `feature-implementation`, `issue-fix`, `documentation`, `dependency-update`.

Briefly explain your routing decision.
