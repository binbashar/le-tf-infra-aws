# Terraform Plan/Apply Output Formats

Single source of truth for how Terraform plan (and, in a later stage, apply)
results are formatted — both for the local Claude Code skills (`/tf-plan`,
`/tf-plan-full`) and for the CI PR comments produced by `ci-analyze-plan.md`.

Skills and workflows **reference this document** instead of re-defining the
format, so every surface renders consistently.

---

## Where the complete plan lives

The `run-terraform-plan` job **always uploads the complete, unfiltered plan as an
artifact** (`plan-<layer>`: `plan-output.txt` + `tfplan.bin` + `plan-sha.txt`,
7-day retention). The artifact is the authoritative, never-truncated copy.

A GitHub issue/PR comment is capped at **65,536 characters**, so any inline full
output must be size-bounded — embed at most **~60,000 characters** of plan text
to leave headroom for the summary, assessment, and markdown scaffolding, and link
to the artifact when truncated.

---

## DELTA format (default)

Used for: PR auto-plan, `/tofu plan` (`/tf-plan`), and the `/tf-plan` skill.

Show **only the resources that will change** plus a meaningful summary, then a
collapsed dropdown carrying the full output. Omit all `# (no changes)` / no-op
resources from the delta section.

```
## Terraform Plan — <layer path>

Summary: <one sentence describing WHAT the change accomplishes — e.g.
"Creates a KMS-encrypted Secrets Manager secret for the API key and grants the
devops role read access" — NOT just "2 resources will be created">

# aws_secretsmanager_secret.api_key will be created
+ resource "aws_secretsmanager_secret" "api_key" {
    + kms_key_id = "arn:aws:kms:us-east-1:..."
    + name       = "bb-apps-devstg-api-key"
  }

# aws_s3_bucket.logs will be updated in-place
~ resource "aws_s3_bucket" "logs" {
    ~ versioning {
        ~ enabled = false -> true
      }
  }

Plan: X to add, X to change, X to destroy.

<assessment — security / cost / risk; call out destroy/replace if DestructionCount > 0>

<details>
<summary>Full plan output</summary>

```
<complete tofu plan output, capped at ~60,000 chars>
... (truncated — download the `plan-<layer>` artifact for the complete output)
```

</details>

📦 Complete plan: **`plan-<layer>`** artifact (7-day retention).
```

Resource change prefixes: `+` create, `~` update in-place, `-` destroy,
`-/+` replace.

When there are no changes, skip the dropdown:

```
## Terraform Plan — <layer path>

Summary: No infrastructure changes detected — the layer is already up to date.

Plan: 0 to add, 0 to change, 0 to destroy.
```

---

## FULL format

Used for: `/tofu plan full` (`/tf-plan full`), and the `/tf-plan-full` skill.

Same comment, but the **full output is promoted to the top (uncollapsed)** rather
than tucked into a dropdown — still prefixed with the `Summary:` line and the
assessment, and still subject to the ~60,000-char cap + artifact pointer. The
local `/tf-plan-full` skill prints the complete output to the terminal unfiltered
(no cap, no artifact — there is no PR comment locally).

---

## Standard PR-comment structure (CI)

When `ci-analyze-plan.md` posts a PR comment, use this order:

1. **Heading** — `## Terraform Plan — <layer path>`.
2. **Summary** — the one-sentence intent line (derived from the code diff).
3. **Delta body** — changed resources only (DELTA), or the full output at top (FULL).
4. **Assessment** — security / cost / risk notes. If `DestructionCount > 0`,
   call out the destroy/replace resources explicitly here.
5. **Full-plan dropdown** — collapsed `<details>` (DELTA mode only; capped).
6. **Artifact pointer** — name the `plan-<layer>` artifact for the complete copy.

The AI may expand the assessment when something needs highlighting; it should not
restate unchanged resources in DELTA mode.
