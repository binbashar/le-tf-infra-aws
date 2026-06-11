# Claude Code on AWS Bedrock — local sessions (data-science account)

How to run **local Claude Code sessions against Amazon Bedrock** in the
`data-science` account, while keeping the **native Anthropic API as the
default** for everyday sessions. This complements the CI-side `@claude` PR
reviewer (see [`README.md`](README.md) §4), which already routes through
Bedrock in `apps-prd`.

```text
claude            → native Anthropic API (subscription login)   [default]
claude-bedrock    → Amazon Bedrock, data-science account        [opt-in]
```

---

## 1. How the routing works (and why it broke before)

Claude Code switches to Bedrock when `CLAUDE_CODE_USE_BEDROCK=1` plus AWS
credentials/region are present in its environment. Two precedence rules govern
the whole setup — both verified empirically on Claude Code `v2.1.172`:

1. **A settings-file `env` block overrides shell-exported variables.** Any
   variable defined under `env` in `.claude/settings.local.json` (or any other
   settings scope) wins over the same variable exported in your shell before
   launching `claude`. The official docs state the opposite; the observed
   behavior is settings-wins.
2. **`AWS_PROFILE` beats env-key credentials.** When `AWS_PROFILE` reaches the
   AWS JS SDK inside Claude Code, the profile is used even if valid
   `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` are also
   present in the environment.

Consequence: **mode-dependent variables must never be pinned in a settings
`env` block** — otherwise no shell wrapper can flip a session to Bedrock. The
project `.claude/settings.local.json` may keep the always-true values only:

```json
{
  "env": {
    "AWS_CONFIG_FILE": "/Users/<you>/.aws/bb/config",
    "AWS_SHARED_CREDENTIALS_FILE": "/Users/<you>/.aws/bb/credentials",
    "AWS_REGION": "us-east-1"
  }
}
```

Keep `CLAUDE_CODE_USE_BEDROCK`, `AWS_PROFILE`, and `ANTHROPIC_MODEL` **out**
of every settings `env` block. The shell (wrapper) provides them per
invocation.

## 2. Prerequisites

- Leverage CLI SSO session and fresh per-profile credentials:

  ```bash
  leverage aws sso login                 # browser; refreshes the SSO token
  cd data-science/us-east-1/bedrock-agentcore
  leverage tofu refresh-credentials      # writes bb-data-science-devops temp keys
  ```

- The target models must be **entitled** in the account *and* have non-zero
  **service quotas** (see §5 — these are two separate gates).

## 3. Install the `claude-bedrock` launcher

Save as `~/.local/bin/claude-bedrock` and `chmod +x` it:

```bash
#!/usr/bin/env bash
#
# claude-bedrock — launch Claude Code against Amazon Bedrock (data-science account)
#
# Shell-exported env vars only take effect because the project settings.local.json
# does NOT pin CLAUDE_CODE_USE_BEDROCK / AWS_PROFILE — plain `claude` keeps using
# the native Anthropic endpoints.
#
# Model override:  CLAUDE_BEDROCK_MODEL=us.anthropic.claude-sonnet-4-6 claude-bedrock
set -euo pipefail

export AWS_CONFIG_FILE="$HOME/.aws/bb/config"
export AWS_SHARED_CREDENTIALS_FILE="$HOME/.aws/bb/credentials"
export AWS_PROFILE="${CLAUDE_BEDROCK_PROFILE:-bb-data-science-devops}"
export AWS_REGION="${CLAUDE_BEDROCK_REGION:-us-east-1}"

export CLAUDE_CODE_USE_BEDROCK=1
export ANTHROPIC_MODEL="${CLAUDE_BEDROCK_MODEL:-us.anthropic.claude-opus-4-8}"
export ANTHROPIC_DEFAULT_OPUS_MODEL="us.anthropic.claude-opus-4-8"
export ANTHROPIC_DEFAULT_SONNET_MODEL="us.anthropic.claude-sonnet-4-6"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="us.anthropic.claude-haiku-4-5-20251001-v1:0"

# A SECOND, explicit Opus row (4.6) next to the 4.8 alias in the /model picker —
# see "Pinning a second Opus version in the /model picker" below.
export ANTHROPIC_CUSTOM_MODEL_OPTION="us.anthropic.claude-opus-4-6-v1"
export ANTHROPIC_CUSTOM_MODEL_OPTION_NAME="us.anthropic.claude-opus-4-6-v1"
export ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION="Cross-region inference profile (Amazon Bedrock)"

# Preflight: Leverage temp credentials go stale independently of the SSO token.
if ! aws sts get-caller-identity --output text --query Account >/dev/null 2>&1; then
  echo "ERROR: AWS credentials for profile '$AWS_PROFILE' are stale or missing." >&2
  echo "Fix (from the le-tf-infra-aws repo):" >&2
  echo "  leverage aws sso login   # only if the SSO token itself expired" >&2
  echo "  cd data-science/us-east-1/bedrock-agentcore && leverage tofu refresh-credentials" >&2
  exit 1
fi

# Export static credentials into the environment. Env-key credentials outrank
# profile resolution in the AWS SDK chain, so a settings file that pins
# AWS_PROFILE to another account cannot redirect the Bedrock session.
eval "$(aws configure export-credentials --profile "$AWS_PROFILE" --format env)"

echo "claude-bedrock: profile=$AWS_PROFILE region=$AWS_REGION model=$ANTHROPIC_MODEL"
exec claude "$@"
```

Usage:

```bash
claude-bedrock                                              # Opus 4.8 on Bedrock
CLAUDE_BEDROCK_MODEL=us.anthropic.claude-sonnet-4-6 claude-bedrock   # Sonnet 4.6
claude-bedrock -p "one-shot prompt"                         # headless print mode
```

Bedrock model IDs use the **cross-region inference-profile** form (`us.`
prefix), but the **suffix is inconsistent across versions — don't extrapolate
one ID from another.** Opus 4.8 is bare (`us.anthropic.claude-opus-4-8`), Opus
4.6 carries a `-v1` (`us.anthropic.claude-opus-4-6-v1`), Opus 4.5 a dated
`-vN:0` (`us.anthropic.claude-opus-4-5-20251101-v1:0`), and Haiku 4.5 likewise
(`us.anthropic.claude-haiku-4-5-20251001-v1:0`). Always confirm the exact ID
from the account rather than guessing:

```bash
aws bedrock list-inference-profiles --region us-east-1 --profile bb-data-science-devops \
  --query "inferenceProfileSummaries[?contains(inferenceProfileId,'anthropic')].inferenceProfileId" --output text
```

### Pinning a second Opus version in the `/model` picker

In a Bedrock session the `/model` list is built from the launcher's env vars,
not a fixed catalog — each variable injects one row (verified on Claude Code
`v2.1.172`):

| Picker row | Driven by |
| --- | --- |
| `us.anthropic.claude-sonnet-4-6` — *Custom Sonnet model* | `ANTHROPIC_DEFAULT_SONNET_MODEL` |
| `us.anthropic.claude-opus-4-8` — *Custom Opus model* | `ANTHROPIC_DEFAULT_OPUS_MODEL` |
| `us.anthropic.claude-haiku-…` — *Custom Haiku model* | `ANTHROPIC_DEFAULT_HAIKU_MODEL` |
| **Opus 4.8 ✔** (active) | `ANTHROPIC_MODEL` |

There is only one Opus slot, so to switch between Opus **4.8** and **4.6** in the
same session the launcher adds one more row via the
`ANTHROPIC_CUSTOM_MODEL_OPTION` trio (its `_NAME` / `_DESCRIPTION` companions set
the label):

```bash
export ANTHROPIC_CUSTOM_MODEL_OPTION="us.anthropic.claude-opus-4-6-v1"
export ANTHROPIC_CUSTOM_MODEL_OPTION_NAME="us.anthropic.claude-opus-4-6-v1"
export ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION="Cross-region inference profile (Amazon Bedrock)"
```

Open `/model` and a **`us.anthropic.claude-opus-4-6-v1`** row appears next to Opus
4.8; `s` switches the current session to it. (Env vars are read at launch, so relaunch `claude-bedrock`
for the row to show.) Because the launcher re-pins `ANTHROPIC_MODEL` on every run,
the picker's `Enter` ("set as default") won't survive a relaunch — to *start* on
4.6 use the existing override:
`CLAUDE_BEDROCK_MODEL=us.anthropic.claude-opus-4-6-v1 claude-bedrock`. This is the
Opus that actually **invokes** today: per §5 the 4.8 TPM quota (`L-DB99DCDB`) is
still 0, so selecting Opus 4.8 fails with `AccessDenied` (not available for this
account) while 4.6 works — and the pin keeps working unchanged once that quota
lands.

**Keep this in the wrapper, never in a settings `env` block.** Per §1 a settings
`env` block also applies to plain `claude` (native Anthropic API), where a
Bedrock inference-profile ID like `us.anthropic.claude-opus-4-6-v1` is rejected as
`dispatching to firstParty` (the §6 404). Exporting it from the launcher keeps
it scoped to Bedrock sessions.

`ANTHROPIC_CUSTOM_MODEL_OPTION` adds exactly **one** extra row. To pin several
models the mechanism is the `availableModels` + `modelOverrides` settings keys
instead — but those live in a settings file (subject to the §1 leak caveat), so
the single env-var row is the right fit for this dual-mode wrapper.

## 4. Who can enable model access (permission sets)

Bedrock model access is an **account-level grant**: once enabled by anyone,
every principal in the account with `bedrock:InvokeModel*` can consume the
model. Per [`management/global/sso/policies.tf`](../../management/global/sso/policies.tf):

| Permission set | `aws-marketplace:*` + `bedrock:*` (manage model access) | `servicequotas:*` (file quota increases) |
| --- | --- | --- |
| **DevOps** | ✅ (verified live) | ✅ (verified live) |
| **DataScientist** | ✅ (inline policy) | ❌ — quota requests must go through DevOps/Administrator |

So either DevOps or DataScientist can accept a model agreement; only
DevOps/Administrator can file the service-quota increases that newer models
also need.

## 5. Model entitlement state (data-science, us-east-1)

Checked 2026-06-10. **Entitlement and quota are separate gates** — a model can
be fully subscribed yet still refuse invokes because AWS ships some new models
with **all token quotas at 0**.

| Model | Agreement | Token quotas | Invokable |
| --- | --- | --- | --- |
| Sonnet 4.6, Opus 4.5/4.6, Haiku 4.5 | ✅ | 6M TPM-class | ✅ |
| **Opus 4.8** | ✅ (accepted 2026-06-10) | **0 — increase pending** | ❌ until quota granted |
| Opus 4.7 | ✅ | 0 | ❌ |

A quota increase for *Cross-region model inference tokens per minute for
Anthropic Claude Opus 4.8* (`L-DB99DCDB`) to the AWS default (30M) was filed on
2026-06-10 → status `CASE_OPENED`. Check progress with:

```bash
aws service-quotas get-service-quota --service-code bedrock \
  --quota-code L-DB99DCDB --region us-east-1 \
  --profile bb-data-science-devops --query 'Quota.Value'
```

Once it returns non-zero, `claude-bedrock` works with Opus 4.8 as-is. Until
then use `CLAUDE_BEDROCK_MODEL=us.anthropic.claude-sonnet-4-6`.

## 6. Troubleshooting

| Symptom | Root cause | Fix |
| --- | --- | --- |
| `There's an issue with the selected model (us.anthropic....)` and debug log shows `dispatching to firstParty` | `CLAUDE_CODE_USE_BEDROCK` pinned/overridden by a settings `env` block — the Bedrock model ID was sent to the native Anthropic API (404) | Remove the key from every settings `env` block (§1) |
| `Failed to authenticate. API Error: 403 The security token included in the request is invalid` | `AWS_PROFILE` pinned in a settings `env` block to a profile with stale credentials — it outranks the wrapper's profile *and* env-key credentials | Remove the `AWS_PROFILE` pin (§1); refresh credentials |
| `AccessDeniedException: <model> is not available for this account` on invoke, while `list-inference-profiles` shows it `ACTIVE` | Model agreement not accepted, **or** (if `get-foundation-model-availability` is all green) token quotas are 0 | Accept the agreement (Bedrock console → Model access, or `create-foundation-model-agreement`); then request the TPM quota (§5) |
| Wrapper preflight fails on `sts get-caller-identity` | Leverage temp credentials expired (SSO token may still be valid) | `leverage tofu refresh-credentials` from any data-science layer; `leverage aws sso login` only if the SSO token itself expired |

To see the real API error behind Claude Code's masked message:

```bash
claude-bedrock -p "test" --debug --debug-file /tmp/claude-debug.log
grep -E "dispatching to|API error" /tmp/claude-debug.log
```

`dispatching to firstParty` = native Anthropic API; Bedrock-mode sessions must
not show `firstParty` with a `us.anthropic.*` model.
