# CLAUDE.md

Guidance for Claude Code when working in this layer.

## Layer Overview

**Documentation-only reference layer** for the `aws-startup-advisor@claude-plugins-official`
plugin (enabled in `.claude/settings.json`). It explains how to use the plugin's five skills
inside this repo across a few representative use cases (architecture advice, GCP→AWS
migration, Activate credits, prompt/agent library), plus a worked migration write-up at
`examples/gcp-saas-migration.md`.

This directory is **prose, not a deployable layer**:

- The trailing ` --` suffix disables it for Atlantis autodiscover and `leverage tofu`.
- It contains **no `.tf` files** — nothing to plan, apply, or lint as HCL.
- There is no backend, remote state, `infracost.yml` entry, or `atlantis.yaml` project.

## Gotchas

- **Keep it code-free.** Don't add `.tf` (or `.tf.example`) files here. The whole point is
  that the plugin *generates* Terraform on demand — a frozen copy would go stale and invite
  review noise (see PR #1116 history). Illustrative snippets belong inline in the markdown,
  kept tiny.
- **Never rename away the ` --` suffix.** It's what excludes the dir from Atlantis/leverage.
- **Plugin is advisory.** It never authenticates or mutates state. Don't wire it into SSO,
  backend, or CI.
- **`.migration/` is plugin scratch.** If you actually run `migration-to-aws`, it writes
  timestamped run dirs to `.migration/`. That's disposable — keep it git-ignored; don't
  commit run output into a layer.
- **AI mappings are compatibility-guided.** OpenAI/Gemini → Bedrock is closest-fit, not 1:1.
  Any doc edit must preserve the "re-validate prompts + evals before cutover" caveat. The
  `us.anthropic.claude-sonnet-4-6` model ID in the example is current/valid — don't let a
  bot "correct" it to an older model.

## Editing this layer

It's Markdown only. No `leverage tofu` commands apply. Just keep the relative links valid
(repo root is three levels up from the layer README, four from `examples/`).
