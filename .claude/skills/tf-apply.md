---
description: "Run terraform apply for the current layer — shows delta plan first and asks for confirmation"
allowed-tools: ["Bash"]
---

# Terraform Apply

Runs `leverage tf apply` for the current layer. **Always shows the delta plan first and asks for explicit confirmation before applying.**

Usage: `/tf-apply`

Run this from inside a Terraform layer directory (e.g. `apps-devstg/us-east-1/secrets-manager/`).

---

# CLAUDE: Execute the following steps

## STEP 1: Validate current directory is a Terraform layer

```bash
# Verify we are inside a valid layer (must have config.tf)
if [[ ! -f "config.tf" ]]; then
  echo "❌ Not a Terraform layer directory — config.tf not found."
  echo "   Run /tf-apply from a layer directory, e.g.:"
  echo "   cd apps-devstg/us-east-1/secrets-manager && /tf-apply"
  exit 1
fi

# Show current layer path relative to repo root
LAYER_PATH=$(git rev-parse --show-prefix 2>/dev/null | sed 's|/$||')
echo "📂 Layer: ${LAYER_PATH:-$(pwd)}"
```

## STEP 2: Run plan and display delta (changed resources only)

```bash
leverage tf plan 2>&1 | tee /tmp/tf-plan-output.txt
PLAN_EXIT=${PIPESTATUS[0]}

if [[ $PLAN_EXIT -ne 0 ]]; then
  echo "❌ Plan failed — apply aborted."
  exit $PLAN_EXIT
fi
```

From `/tmp/tf-plan-output.txt`, display:
1. **Summary**: One sentence describing what these changes accomplish
2. **Only changed resource blocks** (`+`, `~`, `-`, `-/+`) — omit no-op resources
3. **Plan line**: `Plan: X to add, X to change, X to destroy`

If the plan shows **no changes**, output:
```
Summary: No infrastructure changes detected — the layer is already up to date.
Plan: 0 to add, 0 to change, 0 to destroy.

Nothing to apply.
```
And stop — do not run apply.

## STEP 3: Ask for explicit confirmation before applying

**STOP and ask the user**: "The delta plan above shows the pending changes. Do you want to apply these changes to AWS? Type **yes** to confirm or **no** to cancel."

Wait for the user's response. Only proceed if they explicitly type `yes` (case-insensitive). Any other response cancels the apply.

## STEP 4: Run terraform apply

Once the user confirms with `yes`:

```bash
echo "Applying changes..."
leverage tf apply 2>&1
APPLY_EXIT=$?

if [[ $APPLY_EXIT -ne 0 ]]; then
  echo "❌ Apply failed with exit code $APPLY_EXIT"
  exit $APPLY_EXIT
fi
```

## STEP 5: Display apply result summary

After a successful apply, show:
- Resources added, changed, and destroyed (from the apply output)
- Any outputs that changed
- A note on rollback: "To rollback, revert the code changes and run `/tf-apply` again."
