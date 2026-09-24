# Terraform Plan/Apply Output Format

Single source of truth for how Terraform plan (and, in a later stage, apply)
results are presented — both for the local Claude Code skill (`/tf-plan`) and for
the CI PR comments produced by `ci-analyze-plan.md`.

Skills and workflows **reference this document** instead of re-defining the
format, so every surface renders consistently.

---

## Design decision: one format, no separate "full" mode

There is intentionally **no `/tf-plan-full` skill and no `/tofu plan full` toggle**.
The reasoning:

- **Locally**, `leverage tf plan` already prints the complete, unfiltered output
  to the terminal. A "full" wrapper skill would just re-run the same command and
  show the same thing — zero added value. The value-add is `/tf-plan`, which
  distills that output to the **delta** (changed resources + a meaningful
  summary).
- **In CI**, every plan comment already carries the complete plan in a collapsed
  `<details>` dropdown **and** uploads it as the `plan-<layer>` artifact. So the
  full output is always one click (or one download) away; a separate "full"
  command would only toggle collapsed-vs-expanded — not worth the extra surface.

So: locally use `/tf-plan` (delta) or run `leverage tf plan` for raw full output;
in CI every comment is delta + collapsed full dropdown + artifact.

---

## Where the complete plan lives (CI)

The `run-terraform-plan` job **always uploads the complete plan text as an
artifact** (`plan-<layer>`: `plan-output.txt` + `plan-sha.txt`, 7-day retention).
The artifact is the authoritative, never-truncated copy. There is no
`tfplan.bin` in the plan stage — a saved binary plan embeds raw state values,
and artifacts on this public repo are downloadable by anyone; the apply stage
reintroduces it behind its own protections.

**Redaction happens at the source**: the workflow redacts sensitive identifiers
(12-digit AWS account IDs → `<ACCOUNT_ID_REDACTED>`, `AKIA`/`ASIA` access-key
IDs → `***`) in `plan-output.txt` before anything consumes it. Comments and the
artifact therefore never contain raw account IDs — keep the placeholders as-is
and never attempt to reconstruct the original values.

A GitHub issue/PR comment is capped at **65,536 characters**, so the inline full
output in the dropdown must be size-bounded — embed at most **~60,000 characters**
of plan text to leave headroom for the summary, assessment, and markdown
scaffolding, and link to the artifact when truncated.

---

## Plan comment / delta format

Used for: PR auto-plan, `/tofu plan` (`/tf-plan`), and the local `/tf-plan` skill.

Show **only the resources that will change** plus a meaningful summary, then a
collapsed dropdown carrying the full output. Omit all `# (no changes)` / no-op
resources from the delta section.

````text
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

```text
<complete tofu plan output, capped at ~60,000 chars>
... (truncated — download the `plan-<layer>` artifact for the complete output)
```

</details>

📦 Complete plan: **`plan-<layer>`** artifact (7-day retention).
````

Resource change prefixes: `+` create, `~` update in-place, `-` destroy,
`-/+` replace.

When there are no changes, skip the dropdown:

```text
## Terraform Plan — <layer path>

Summary: No infrastructure changes detected — the layer is already up to date.

Plan: 0 to add, 0 to change, 0 to destroy.
```

The local `/tf-plan` skill renders the same delta + summary to the terminal (no
PR comment, no dropdown, no artifact). For raw full output locally, run
`leverage tf plan` directly.

---

## Standard PR-comment structure (CI)

When `ci-analyze-plan.md` posts a PR comment, use this order:

1. **Heading** — `## Terraform Plan — <layer path>`.
2. **Summary** — the one-sentence intent line (derived from the code diff).
3. **Delta body** — changed resources only.
4. **Assessment** — security / cost / risk notes. If `DestructionCount > 0`,
   call out the destroy/replace resources explicitly here.
5. **Full-plan dropdown** — collapsed `<details>` (capped; truncation pointer).
6. **Artifact pointer** — name the `plan-<layer>` artifact for the complete copy.

The AI may expand the assessment when something needs highlighting; it should not
restate unchanged resources.
