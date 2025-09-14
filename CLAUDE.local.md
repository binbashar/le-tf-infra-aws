# CLAUDE.local.md - le-tf-infra-aws

## REQUIRED Environment Setup

**CRITICAL**: Always activate the Leverage environment before any work in this directory:

```bash
# Navigate to project root and activate Leverage CLI
cd /Users/lgallard/git/binbash
source ./activate-leverage.sh
```

## Quick Reference

### Essential Commands (from layer directories)
```bash
leverage tf init        # Initialize
leverage tf plan        # Plan changes
leverage tf apply       # Apply changes
leverage tf validate    # Validate config
leverage tf fmt         # Format files
```

### Authentication
```bash
leverage aws sso login  # Required before any AWS operations
```

### Working Pattern
1. **Always** activate Leverage first (`source ./activate-leverage.sh`)
2. Navigate to specific layer: `cd {account}/{region}/{layer}`
3. Run Leverage commands from layer directory
4. Use `leverage tf` (shorthand for OpenTofu) for all operations

## Key Notes
- Never use direct `terraform`/`tofu` commands - always use `leverage tf`
- Work from layer directories, not repository root
- Backend state is managed in S3 with DynamoDB locking
- Check dependencies with: `python build.py layer_dependency`