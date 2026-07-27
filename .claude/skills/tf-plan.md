---
description: "Run terraform plan and display only changed resources (delta format) with a meaningful summary"
allowed-tools: ["Bash"]
---

# Terraform Plan — Delta Format

Runs `leverage tf plan` for the current layer and displays **only the resources that will change**, with a one-sentence summary of what the changes accomplish.

Usage: `/tf-plan`

Run this from inside a Terraform layer directory (e.g. `apps-devstg/us-east-1/secrets-manager/`).

The DELTA format is defined in `.claude/docs/output-formats.md` (single source of truth). This skill produces the delta locally in the terminal — there is no PR comment, artifact, or size cap here.

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

From `/tmp/tf-plan-output.txt`, render the **DELTA format** exactly as specified in
`.claude/docs/output-formats.md`:

1. **Generate a meaningful summary line** — one sentence describing *what these changes accomplish* (e.g. "Creates a KMS-encrypted Secrets Manager secret for the API key and grants the devops role read access" — NOT just "2 resources will be created").
2. **Show only changed resource blocks** — prefixed with `+` (create), `~` (update in-place), `-` (destroy), or `-/+` (replace). Omit all `# (no changes)` / no-op resources.
3. **End with the standard plan line**: `Plan: X to add, X to change, X to destroy.`

If there are **no changes** (`No changes. Infrastructure is up-to-date`), output the no-changes block from `output-formats.md`.

To see the complete, unfiltered output instead, run `leverage tf plan` directly (there is no `/tf-plan-full` skill — see the design-decision note in `.claude/docs/output-formats.md`).
