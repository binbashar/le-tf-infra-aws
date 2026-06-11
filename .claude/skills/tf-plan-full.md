---
description: "Run terraform plan and display complete unfiltered output"
allowed-tools: ["Bash"]
---

# Terraform Plan — Full Output

Runs `leverage tf plan` for the current layer and displays the **complete, unfiltered plan output** including all resources (changed and unchanged).

Usage: `/tf-plan-full`

Run this from inside a Terraform layer directory (e.g. `apps-devstg/us-east-1/secrets-manager/`).

Use `/tf-plan` instead if you only need to see what will change (delta format).

---

# CLAUDE: Execute the following steps

## STEP 1: Validate current directory is a Terraform layer

```bash
# Verify we are inside a valid layer (must have config.tf)
if [[ ! -f "config.tf" ]]; then
  echo "❌ Not a Terraform layer directory — config.tf not found."
  echo "   Run /tf-plan-full from a layer directory, e.g.:"
  echo "   cd apps-devstg/us-east-1/secrets-manager && /tf-plan-full"
  exit 1
fi

# Show current layer path relative to repo root
LAYER_PATH=$(git rev-parse --show-prefix 2>/dev/null | sed 's|/$||')
echo "📂 Layer: ${LAYER_PATH:-$(pwd)}"
echo "ℹ️  Running full plan (all resources will be shown)"
```

## STEP 2: Run terraform plan and display complete output

```bash
leverage tf plan 2>&1
PLAN_EXIT=${PIPESTATUS[0]}

if [[ $PLAN_EXIT -ne 0 ]]; then
  echo "❌ Plan failed with exit code $PLAN_EXIT"
  exit $PLAN_EXIT
fi
```

## STEP 3: Display results

Show the complete plan output exactly as produced by `leverage tf plan`. Do not filter or truncate any resources.

After the raw output, append a brief note:

```
---
Tip: Use /tf-plan to see only the resources that will change (delta format).
```
