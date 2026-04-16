---
description: "Run terraform plan and display only changed resources (delta format) with a meaningful summary"
allowed-tools: ["Bash"]
---

# Terraform Plan — Delta Format

Runs `leverage tf plan` for the current layer and displays **only the resources that will change**, with a one-sentence summary of what the changes accomplish.

Usage: `/tf-plan`

Run this from inside a Terraform layer directory (e.g. `apps-devstg/us-east-1/secrets-manager/`).

---

# CLAUDE: Execute the following steps

## STEP 1: Validate current directory is a Terraform layer

```bash
# Verify we are inside a valid layer (must have config.tf)
if [[ ! -f "config.tf" ]]; then
  echo "❌ Not a Terraform layer directory — config.tf not found."
  echo "   Run /tf-plan from a layer directory, e.g.:"
  echo "   cd apps-devstg/us-east-1/secrets-manager && /tf-plan"
  exit 1
fi

# Show current layer path relative to repo root
LAYER_PATH=$(git rev-parse --show-prefix 2>/dev/null | sed 's|/$||')
echo "📂 Layer: ${LAYER_PATH:-$(pwd)}"
```

## STEP 2: Run terraform plan and capture output

```bash
leverage tf plan 2>&1 | tee /tmp/tf-plan-output.txt
PLAN_EXIT=${PIPESTATUS[0]}

if [[ $PLAN_EXIT -ne 0 ]]; then
  echo "❌ Plan failed with exit code $PLAN_EXIT"
  echo "See output above for details."
  exit $PLAN_EXIT
fi
```

## STEP 3: Extract delta (changed resources only) and display

From `/tmp/tf-plan-output.txt`, you MUST:

1. **Generate a meaningful summary line** — Read the plan output and write one sentence describing *what these changes accomplish* (e.g. "Creates a KMS-encrypted Secrets Manager secret for the API key and grants the devops role read access" — NOT just "2 resources will be created").

2. **Extract only changed resource blocks** — Show blocks prefixed with `+` (create), `~` (update in-place), `-` (destroy), or `-/+` (replace). Omit all `# no changes` / no-op resources.

3. **Display in this exact format**:

```
Summary: [your meaningful one-sentence description]

# [resource_type].[name] will be created
+ resource "aws_secretsmanager_secret" "api_key" {
    + kms_key_id = "arn:aws:kms:us-east-1:..."
    + name       = "bb-apps-devstg-api-key"
  }

# [resource_type].[name] will be updated in-place
~ resource "aws_s3_bucket" "logs" {
    ~ versioning {
        ~ enabled = false -> true
      }
  }

Plan: X to add, X to change, X to destroy.
```

If there are **no changes** (plan shows `No changes. Infrastructure is up-to-date`), output:
```
Summary: No infrastructure changes detected — the layer is already up to date.

Plan: 0 to add, 0 to change, 0 to destroy.
```
