# CLAUDE.md

Guidance for Claude Code when working in this layer.

## Layer Overview

**Documentation-only reference layer** for the `aws-startup-advisor@claude-plugins-official`
plugin (enabled in `.claude/settings.json`). It explains how to use the plugin's five skills
inside this repo and ships a fully worked **GCP SaaS → AWS migration** example (fictional
startup "Meridian") under `examples/gcp-saas-migration/`.

This directory is **not a deployable layer**:

- The trailing ` --` suffix disables it for Atlantis autodiscover and `leverage tofu`.
- Example infrastructure uses the `.tf.example` extension — never parsed as real Terraform.
- There is no backend, no remote state, no `infracost.yml` entry, no `atlantis.yaml` project.

## Gotchas

- **Never rename away the ` --` suffix or change `.tf.example` → `.tf`.** Either would make
  Atlantis try to plan fictional cross-cloud infra with no backend — it would fail CI.
- **The example is illustrative, not Leverage-conformant.** The `terraform/*.tf.example`
  files mirror what the plugin's Generate phase emits (raw `hashicorp/aws` resources), on
  purpose — to show the *before* of the refactor-to-Leverage step. Do not "fix" them into
  layer conventions; the README/guide explains that refactor separately.
- **Plugin is advisory.** It never authenticates or mutates state. Don't wire it into SSO,
  backend, or CI.
- **`.migration/` is plugin scratch.** If you actually run `migration-to-aws`, it writes
  timestamped run dirs to `.migration/`. That's disposable — keep it git-ignored; curated
  output belongs under `examples/`.
- **AI mappings are compatibility-guided.** OpenAI/Gemini → Bedrock is closest-fit, not 1:1.
  Any doc edit must preserve the "re-validate prompts + evals before cutover" caveat.

## Editing this layer

It's Markdown + `.tf.example` only. No `leverage tofu` commands apply. To sanity-check the
example Terraform reads correctly you may copy a `*.tf.example` to a scratch dir and run
`tofu fmt`/`validate` there, but never inside this layer.
