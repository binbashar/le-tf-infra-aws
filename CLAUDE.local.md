# CLAUDE.local.md

Local-specific instructions for Claude Code when working in the `le-tf-infra-aws` repository.

## CRITICAL: Environment Setup

**REQUIRED**: Before using any Leverage CLI commands, you MUST activate the Leverage environment:

```bash
# ALWAYS run this first - absolute path to activation script
source /Users/lgallard/git/binbash/activate-leverage.sh
```

This script sets up the necessary environment variables and PATH configurations required for the Leverage CLI to function properly in this repository.

## Verification

After activation, verify the setup:

```bash
# Check that leverage command is available
which leverage

# Verify project context
leverage --version
```

## Workflow Integration

All Leverage CLI operations must be preceded by the activation:

```bash
# Complete workflow example
source /Users/lgallard/git/binbash/activate-leverage.sh
leverage aws sso login
cd apps-devstg/us-east-1/base-network
leverage tf plan
```

## Important Notes

- This activation is **repository-specific** and required for this particular Leverage infrastructure project
- The activation script must be sourced (not executed) to properly set environment variables
- Re-run the activation script if you encounter "command not found" errors with `leverage`
- This supplements the comprehensive documentation in the main `CLAUDE.md` file