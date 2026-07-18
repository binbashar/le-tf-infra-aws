# Claude Code on AWS Bedrock — local sessions

How to run **local Claude Code sessions against Amazon Bedrock** in the binbash
accounts, while keeping the **native Anthropic API as the default** for everyday
sessions.

> **Two separate Bedrock integrations live in this repo — different accounts,
> different purposes. Don't conflate them:**
>
> | Integration | Account | Who / what runs it |
> | --- | --- | --- |
> | CI `@claude` PR reviewer | **`apps-prd`** (prod) | GitHub Actions — see [`README.md`](README.md) §4 |
> | `claude-bedrock` local sessions | **`apps-prd`** or **`data-science`** (you pick) | humans, on their own machines (this doc) |
>
> The launcher targets whichever account + role you choose at launch; it never
> touches the native Anthropic API.

```text
claude            → native Anthropic API (subscription login)            [default]
claude-bedrock    → Amazon Bedrock — account + role chosen at launch      [opt-in]
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
of every settings `env` block. The launcher provides them per invocation.

## 2. Prerequisites

- A Leverage CLI **SSO session**:

  ```bash
  leverage aws sso login                 # browser; refreshes the SSO token
  ```

  The per-profile temp credentials are refreshed **automatically** by the launcher
  when they go stale (see §3.2) — you only run `leverage aws sso login` yourself
  when the SSO *session* itself has expired.

- Access to the account you want (see §4) with a role that has `bedrock:*`
  (DevOps or DataScientist), and the target model **enabled + quota'd** in that
  account (see §5 — four separate gates). **Fable 5 / Mythos 5 have an extra,
  account-wide data-sharing gate** — read §5.1 before selecting them.

## 3. Install the `claude-bedrock` launcher

The launcher is committed at [`doc/ai-sdlc/bin/claude-bedrock`](bin/claude-bedrock).
Symlink it onto your `PATH` — nothing to copy or keep in sync, and it auto-locates
this repo from its own path for the credential auto-refresh (§3.2):

```bash
ln -s "$(git rev-parse --show-toplevel)/doc/ai-sdlc/bin/claude-bedrock" ~/.local/bin/claude-bedrock
```

Usage:

```bash
claude-bedrock                                   # prompts for account + role, then launches
claude-bedrock -p "one-shot prompt"              # headless print mode (no prompts; env/defaults)
CLAUDE_BEDROCK_MODEL=us.anthropic.claude-sonnet-5 claude-bedrock   # force a model for this run
```

### 3.1 Account + role selection

On launch the wrapper asks which **account** and **SSO role** to use, then sets the
matching profile (`bb-<account>-<role>`), the models that account actually has, and
the credential-refresh layer. Non-interactively (or under `-p`) it uses the env vars
/ defaults instead of prompting.

| Account | Models available today | Default role |
| --- | --- | --- |
| **`data-science`** (default) | Opus 4.6 / Sonnet 4.6 / Haiku 4.5 — **Opus 4.8, Sonnet 5 & Fable 5 quota pending** (§5) | `devops` |
| **`apps-prd`** (prod) | **Opus 4.8 / Sonnet 5** / Haiku 4.5 — live today; **Fable 5 live after the §5.1 data-retention opt-in** | `devops` |

Not everyone has DevOps (some users only have DataScientist, etc.), so the role is a
choice too. The launcher validates `bb-<account>-<role>` against your
`~/.aws/bb/config` and, if it's missing, prints the profiles you *do* have.

Overrides (env wins over the prompts):

| Env var | Default | Purpose |
| --- | --- | --- |
| `CLAUDE_BEDROCK_ACCOUNT` | `data-science` | `data-science` \| `apps-prd` |
| `CLAUDE_BEDROCK_ROLE` | `devops` | `devops` \| `datascientist` |
| `CLAUDE_BEDROCK_MODEL` | account default | active model for this session |
| `CLAUDE_BEDROCK_PROFILE` | `bb-<account>-<role>` | override the whole profile |
| `CLAUDE_BEDROCK_REPO` | auto-derived from the script path | your `le-tf-infra-aws` checkout |
| `CLAUDE_BEDROCK_AUTO_REFRESH` | `1` | `0` to skip the auto-refresh (§3.2) |

### 3.2 Automatic credential refresh

Leverage temp credentials go stale independently of the SSO token. On each run the
launcher checks `aws sts get-caller-identity`; if it fails, it auto-runs
`leverage tofu refresh-credentials` from the chosen account's layer
(`data-science/us-east-1/bedrock-agentcore` or `apps-prd/us-east-1/notifications`)
to mint fresh keys into `~/.aws/bb/credentials`. That call only writes local
credentials — it never runs `plan`/`apply` or touches state or infra, which is why
it's safe to automate and safe to ship in this public repo. The wrapper also confers
no access on its own: with no valid SSO session the refresh fails closed and it exits.

**Caveat — roles:** `refresh-credentials` mints the layer's **DevOps** profile, so
the auto-refresh only covers `role=devops`. A non-DevOps role whose static creds
aren't already minted falls through to the manual hint (run `leverage aws sso login`
and mint that role's creds). Only an **expired SSO session** ever needs the manual,
non-automatable browser login.

### 3.3 The `/model` picker

In a Bedrock session the `/model` list is built from the launcher's env vars, not a
fixed catalog — each `ANTHROPIC_DEFAULT_*_MODEL` tier slot (Opus / Sonnet / Haiku /
**Fable**) and the single `ANTHROPIC_CUSTOM_MODEL_OPTION` injects one row (verified on
Claude Code `v2.1.212`). Each accepts `_NAME` and `_DESCRIPTION` suffix variables
([model-config docs](https://code.claude.com/docs/en/model-config)); the launcher sets
only `_DESCRIPTION` — labelling every row **Amazon Bedrock · `<account>` account** so the
routing is obvious — and leaves the **name** as the raw `us.anthropic.*` inference-profile
ID (unambiguous evidence you're on Bedrock, not the native API). Example rows for an
**apps-prd** session:

| Picker row (name — description) | Driven by |
| --- | --- |
| `us.anthropic.claude-sonnet-5` — *Amazon Bedrock · apps-prd account (balanced)* | `ANTHROPIC_DEFAULT_SONNET_MODEL` + `_DESCRIPTION` |
| `us.anthropic.claude-opus-4-8` — *Amazon Bedrock · apps-prd account (most capable Opus)* | `ANTHROPIC_DEFAULT_OPUS_MODEL` + `_DESCRIPTION` |
| `us.anthropic.claude-haiku-…` — *Amazon Bedrock · apps-prd account (fast, low-cost)* | `ANTHROPIC_DEFAULT_HAIKU_MODEL` + `_DESCRIPTION` |
| `us.anthropic.claude-fable-5` — *Amazon Bedrock · apps-prd account (Fable 5 — most capable, premium; needs provider_data_share opt-in)* | `ANTHROPIC_DEFAULT_FABLE_MODEL` + `_DESCRIPTION` |
| `us.anthropic.claude-opus-4-6-v1` — *Amazon Bedrock · apps-prd account (Opus 4.6 fallback)* | `ANTHROPIC_CUSTOM_MODEL_OPTION` trio |

**Fable is a first-class tier slot** (`ANTHROPIC_DEFAULT_FABLE_MODEL`) alongside Opus /
Sonnet / Haiku — so it gets its own always-visible row **without** spending the single
custom slot (which still holds the Opus 4.6 fallback). Selecting it, however, is gated
on the account's data-retention mode — see **§5.1**.

A `data-science` session shows the same shape with that account's models (Opus 4.6 /
Sonnet 4.6, Fable 5 marked "quota pending", plus Opus 4.8 as a "quota pending" custom
row). There is exactly **one** custom slot: `ANTHROPIC_CUSTOM_MODEL_OPTION` (no numbered
or array variant). For several *extra* non-tier models the mechanism is the
`availableModels` / `modelOverrides` settings keys, but those live in a settings file
(subject to the §1 leak caveat), so the tier slots + one env-var custom row fit this
dual-mode wrapper.

**Bedrock model-ID caveat:** IDs use the cross-region inference-profile form (`us.`
prefix), but the **suffix is inconsistent across versions — don't extrapolate one ID
from another.** Current-generation models are bare — Opus 4.8
(`us.anthropic.claude-opus-4-8`), Sonnet 5 (`us.anthropic.claude-sonnet-5`) — while
older ones carry suffixes: Opus 4.6 a `-v1`, Opus 4.5 a dated `-vN:0`, Haiku 4.5
likewise (`us.anthropic.claude-haiku-4-5-20251001-v1:0`). Always confirm from the
account:

```bash
aws bedrock list-inference-profiles --region us-east-1 --profile bb-<account>-devops \
  --query "inferenceProfileSummaries[?contains(inferenceProfileId,'anthropic')].inferenceProfileId" --output text
```

## 4. Who can enable model access (permission sets)

Bedrock model access is an **account-level grant**: once enabled by anyone, every
principal in the account with `bedrock:InvokeModel*` can consume the model. Per
[`management/global/sso/policies.tf`](../../management/global/sso/policies.tf):

| Permission set | `aws-marketplace:*` + `bedrock:*` (manage + invoke) | `servicequotas:*` (file quota increases) |
| --- | --- | --- |
| **DevOps** | ✅ (region-conditioned to us-east-1/us-east-2/us-west-2) | ✅ |
| **DataScientist** | ✅ (same region condition) | ❌ — quota requests go through DevOps/Administrator |

Both `bedrock:*` grants are conditioned on `aws:RequestedRegion ∈
{us-east-1, us-east-2, us-west-2}`, which covers the regions the `us.` cross-region
inference profiles route to — so IAM is **not** what blocks a new model (verified: the
DevOps role invokes Sonnet 4.6 / Opus 4.6 / Haiku 4.5 today). What's missing for a new
model is gate 1/2 below, not IAM.

## 5. Model availability — the four gates (checked 2026-07-18, us-east-1)

Four **independent** gates must all pass to invoke a model. A model can clear some and
still refuse:

1. **Model access** — the agreement is accepted for that model, per account (Bedrock
   console → *Model access*).
2. **Service quota (TPM)** — non-zero, per model, per account, and per profile family
   (`us.` cross-region vs `global.` global-cross-region have *separate* quotas).
3. **IAM** — your SSO role allows `bedrock:InvokeModel*` (see §4 — DevOps/DataScientist do).
4. **Data-retention mode** — the account's effective retention mode must be in the
   model's `allowed_modes`. **Only Fable 5 / Mythos 5 gate on this** (they allow
   `provider_data_share` *only*); every older Claude model allows `default`, so gate 4 is
   a no-op for them. See **§5.1**.

| Model | `apps-prd` | `data-science` |
| --- | --- | --- |
| Opus 4.6, Sonnet 4.6, Haiku 4.5 | ✅ | ✅ |
| **Opus 4.8** | ✅ | ⏳ **quota pending** |
| **Sonnet 5** | ✅ | ⏳ **quota pending** |
| **Fable 5** | ✅ **(after §5.1 opt-in — done 2026-07-18)** | ❌ quota pending **+** needs §5.1 opt-in |

So **use `apps-prd` for Opus 4.8 / Sonnet 5 / Fable 5 today**; in `data-science` the launcher's
`us.` profiles return *"not available for this account"* — a gate-1/2 (access/quota)
block, **not** IAM. Heads-up: the pending Service Quotas cases you may see are for the
separate **`global.*`** family (*Global cross-region* Opus 4.8 / Sonnet 5), which the
launcher does **not** use (and which the region condition blocks by design, §4) — so
they won't unblock the launcher on their own. Turning on data-science's **`us.`**
models is its own model-access + `us.`-quota step. Check a quota with:

```bash
aws service-quotas get-service-quota --service-code bedrock \
  --quota-code L-DB99DCDB --region us-east-1 \
  --profile bb-data-science-devops --query 'Quota.Value'
```

> **The console's IAM-worded error is misleading.** The Bedrock console playground may
> surface a missing model as *"not authorized to perform bedrock:InvokeModelWithResponseStream"*,
> but the reproducible gate is access/quota (`converse` returns *"not available for this
> account"*). The role's `bedrock:*` is fine — don't go editing permission sets for this.

### 5.1 ⚠️ Data-retention gate — Fable 5 / Mythos 5 only (account-wide setting, per-model effect)

> [!IMPORTANT]
> **Selecting Fable 5 or Mythos 5 requires setting the AWS account's data-retention
> mode to `provider_data_share`.** This is the **required trust-&-safety posture** that
> AWS and Anthropic mandate for these frontier models — not an optional or unsafe
> toggle. It is a **governance acknowledgement**, and the sharing is **scoped per model**
> (see the blast-radius table below): only Fable 5 / Mythos 5 share data with Anthropic;
> every other model in this launcher stays **AWS-only**. It is still an **account-wide
> setting**, so get **sign-off** before enabling it on a shared or production account.

**Security / compliance framing.** `provider_data_share` is how AWS and Anthropic jointly
satisfy the trust-&-safety and abuse-monitoring obligations that gate access to these
frontier models. Prompts and completions for **Fable 5 / Mythos 5 requests only** are
retained for up to **30 days** for trust-and-safety purposes under the
[AWS Service Terms](https://aws.amazon.com/service-terms/) and the
[Anthropic third-party-model terms](https://aws.amazon.com/legal/bedrock/third-party-models/);
the data stays within the AWS/Anthropic contractual boundary (governed, access-controlled,
compliance-audited under AWS's US regulatory posture) — it is **not** general "data
sharing" and **not** used for model training. Setting the mode is the account's explicit,
auditable opt-in to that posture. If your account has a compliance requirement for **zero**
retention, you cannot use Fable 5 / Mythos 5 without a per-account/per-model ZDR exception
(contact your AWS account manager) — and you can **enforce** a retention ceiling
org-wide with an SCP on the `bedrock:DataRetentionMode` / `bedrock-mantle:DataRetentionMode`
condition key (see the AWS data-retention docs → *Enforcing retention policy with IAM*).

**Blast radius is per-model, not account-wide (this is the key point).** Setting the
account to `provider_data_share` does **not** make every model start sharing data. Each
model declares an `allowed_modes` list, and that list — not the account setting — decides
what actually happens to a given model's data:

| Model (this launcher) | `allowed_modes` | Under account = `provider_data_share` |
| --- | --- | --- |
| **Fable 5 / Mythos 5** | `["provider_data_share"]` | **Retained + shared with Anthropic** (≤30 d, trust & safety) — this is the whole point |
| Opus 4.6/4.8, Sonnet 4.6/5, Haiku 4.5 | `["default","provider_data_share"]` | **AWS-only** — retained by AWS for abuse detection, **never shared with Anthropic** |

So on `apps-prd` the **CI `@claude` PR reviewer runs on Sonnet, which is `default`-capable
→ its prompts/source stay AWS-only and are NOT shared with Anthropic.** The account-wide
setting unlocks Fable 5 without changing the data path of any older model. (A Fable 5
request that a safety classifier declines and that falls back to Opus 4.8 via fallback
credit follows **Opus 4.8's** AWS-only rules for the fallback invocation, not Fable 5's.)

**Why only these two models.** Every Claude model on Bedrock declares which retention
modes it permits via `allowed_modes` (table above). Older models allow `default`, so they
work under any account setting **and never leave AWS**. **Fable 5 and Mythos 5 declare
`allowed_modes: ["provider_data_share"]` only** — they refuse `default` (and `none`),
which is the trust-&-safety gate for frontier access.

**How the effective mode is resolved.** `first non-inherit value of (account → model
default)`. A fresh account is `inherit`, which falls through to the model default
(`default`) — so Fable 5 is blocked until you explicitly set `provider_data_share` at the
**account** scope.

**The symptom** when it's not set (this is *not* an access/quota or IAM error):

```text
API Error: 400 data retention mode 'default' is not available for this model
```

The request reached Bedrock and the model is `ACTIVE` — it's policy-gated, not missing.

**Check the current account mode** (read-only). `awscli` (2.27.x) has no `data-retention`
subcommand, so sign the control-plane REST call directly (`bedrock` service, SigV4). Modern
`curl` (7.75.0+) signs it natively via `--aws-sigv4`, reading the same `AWS_ACCESS_KEY_ID` /
`AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` the launcher already exports for the session:

```bash
# via the bb SSO profile; returns e.g. {"mode":"inherit","updatedAt":null}
curl -s --aws-sigv4 "aws:amz:us-east-1:bedrock" \
  --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
  -H "X-Amz-Security-Token: $AWS_SESSION_TOKEN" \
  "https://bedrock.us-east-1.amazonaws.com/data-retention"
```

**Opt in** (the write — account-wide; needs governance sign-off):

```bash
curl -s -X PUT "https://bedrock.us-east-1.amazonaws.com/data-retention" \
  --aws-sigv4 "aws:amz:us-east-1:bedrock" \
  --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
  -H "X-Amz-Security-Token: $AWS_SESSION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"mode":"provider_data_share"}'
```

**Scope note.** The commands above use the **account-level** control-plane endpoint
(`bedrock.{region}.amazonaws.com/data-retention`), which is what the bb DevOps SSO role can
reach and is the scope we use. Bedrock *also* exposes a **project-level** retention setting
on the separate `bedrock-mantle` data plane (`POST /v1/organization/projects/{id}` →
`bedrock-mantle:UpdateProject`), but that action is **not granted** to our SSO roles
(verified: `bedrock-mantle:*` returns `access_denied`), so project-scoping isn't usable here
without a permission-set change. **Reversible** at any time with `PUT {"mode":"inherit"}`
(back to the model default) or `{"mode":"none"}` (zero retention) — but data retained/shared
while `provider_data_share` was active cannot be un-shared.

**Enforce a ceiling (compliance).** To *guarantee* an account or the whole org can never be
set beyond a given posture, attach an SCP/IAM policy that denies the write actions
(`bedrock:PutAccountDataRetention` / `bedrock-mantle:PutAccountDataRetention`,
`bedrock-mantle:UpdateProject`) unless the `bedrock:DataRetentionMode` /
`bedrock-mantle:DataRetentionMode` condition key matches your allowed value — e.g. deny
anything other than `none` to hard-block Fable 5 in ZDR-required accounts. See the AWS
data-retention docs → *Enforcing retention policy with IAM*.

**Status:** `apps-prd` was opted in at the **account** scope on **2026-07-18** (with explicit
sign-off) and Fable 5 is live there; older models on `apps-prd` remain AWS-only per the
blast-radius table above (the CI `@claude` reviewer's data is not shared). `data-science`
has **not** been opted in — Fable 5 there needs both its pending quota (§5) *and* this opt-in.

Full reference: [Bedrock data-retention docs](https://docs.aws.amazon.com/bedrock/latest/userguide/data-retention.html).

## 6. Troubleshooting

| Symptom | Root cause | Fix |
| --- | --- | --- |
| `AccessDeniedException: <model> is not available for this account` (or a console `InvokeModelWithResponseStream` error) | Model **access or quota** not granted for that model **in that account** (gate 1/2, §5) — **not** IAM | Use `apps-prd` (has Opus 4.8 / Sonnet 5), or enable access + wait for the data-science quota case |
| `400 data retention mode 'default' is not available for this model` (Fable 5 / Mythos 5 only) | Account not opted into `provider_data_share` (gate 4, §5.1) — the model is `ACTIVE`; it's policy-gated, not missing | Set the **account** data-retention mode to `provider_data_share` per §5.1 — **account-wide setting** (sharing is per-model; only Fable/Mythos share — §5.1 table), get sign-off first |
| `There's an issue with the selected model (us.anthropic....)`; debug log shows `dispatching to firstParty` | `CLAUDE_CODE_USE_BEDROCK` pinned/overridden by a settings `env` block — the Bedrock model ID went to the native Anthropic API (404) | Remove the key from every settings `env` block (§1) |
| `403 The security token included in the request is invalid` | `AWS_PROFILE` pinned in a settings `env` block to a stale profile — it outranks the wrapper | Remove the `AWS_PROFILE` pin (§1); refresh credentials |
| `ERROR: AWS profile 'bb-…' not found` | You don't have that account/role combo | Pick a profile the launcher lists (from your `~/.aws/bb/config`) |
| `ERROR: no valid AWS credentials … after auto-refresh` | SSO session expired, or a non-DevOps role whose creds aren't minted (§3.2) | `leverage aws sso login` (browser), then re-run; for non-DevOps, mint that role's creds |

To see the real API error behind Claude Code's masked message:

```bash
claude-bedrock -p "test" --debug --debug-file /tmp/claude-debug.log
grep -E "dispatching to|API error" /tmp/claude-debug.log
```

`dispatching to firstParty` = native Anthropic API; Bedrock-mode sessions must not
show `firstParty` with a `us.anthropic.*` model.
