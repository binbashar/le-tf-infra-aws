# OpenTofu pull-request plan POC

This proof of concept adds a native GitHub Actions check for OpenTofu changes without
introducing Atlantis, a custom GitHub App, automated apply, or PR comments. It is intentionally
limited to one allowlisted layer while the AWS role and report redaction are validated.

Workflow: [`.github/workflows/tofu-plan-poc.yml`](../../.github/workflows/tofu-plan-poc.yml).

Staged activation and rollback checklist:
[`tofu-plan-poc-rollout.md`](tofu-plan-poc-rollout.md).

## Current scope

- Runs on PR open, reopen, ready-for-review, and every new PR commit (`synchronize`), but only for
  non-draft same-repository PRs authored by an `OWNER`, `MEMBER`, or `COLLABORATOR`. Fork PRs and
  bot-authored PRs register no runner work; supporting external contributors is outside this POC.
- A newer commit cancels an in-progress stale run; the cancelled run remains in Actions history.
- Detects root modules by the nearest `config.tf`, including nested layers. It does not assume an
  `account/region/layer` depth.
- Expands changes under `config/` or `<account>/config/`, but never silently truncates a scope that
  exceeds the configured POC limit.
- Excludes any path with a segment ending in `--` and records why it was skipped.
- Defaults to the existing `apps-devstg/global/cli-test-layer` integration layer. Override it with
  the `TOFU_PLAN_POC_LAYER` repository variable only after validating the new layer's providers,
  data sources, backend, remote states, profiles, and README/deployment notes.
- Changes to the POC workflow or its Python package self-test that allowlisted layer, so the POC's
  own PR exercises more than a no-op discovery path. Those and other execution-control changes are
  always static-only and cannot reach a credentialed job.
- Runs credential-free `tofu init -backend=false -lockfile=readonly` and `tofu validate` by default.
- Runs a live backend init and speculative plan only when explicitly enabled with an OIDC role and
  approved through the protected `tofu-plan-poc` GitHub environment.
- Uploads only sanitized JSON/Markdown reports. It never uploads the binary plan, prior state,
  variables, full UI stream, or before/after values.
- Can ask Bedrock to explain the sanitized projection. The model is advisory and cannot change the
  deterministic check result.

There is no apply path in this workflow.

## Workflow layout

The workflow intentionally keeps five visible orchestration jobs: discovery, credential-free
validation, protected live planning, optional Bedrock analysis, and the stable aggregate report.
Their imperative mechanics live in
[`workflow.py`](../../@bin/scripts/tofu_plan_ci/workflow.py) behind matching `discover`, `static`,
`live`, `analyze`, and `aggregate` commands. This keeps credentials and job dependencies visible in
GitHub Actions while making command construction, cleanup, reporting, and failure behavior unit
testable without long inline shell blocks.

## GitHub configuration

The default credential-free mode needs no repository configuration. It is suitable for validating
the workflow mechanics in a PR before granting AWS access.

Live planning requires:

| Kind | Name | Purpose |
| --- | --- | --- |
| Variable | `TOFU_PLAN_POC_LIVE` | Must equal `true` to request live planning. |
| Variable | `TOFU_PLAN_POC_LAYER` | The single layer allowed by the POC. Defaults to `apps-devstg/global/cli-test-layer`. |
| Variable | `TOFU_PLAN_POC_MAX_LAYERS` | Safety cap. Defaults to `1`. No subset is chosen when exceeded. |
| Variable | `AWS_TOFU_PLAN_ROLE_ARN` | OIDC role assumed by the plan job. This must not be `DeployMaster`. |
| Variable | `AWS_TOFU_PLAN_ACCOUNT_ID` | Exact AWS account allowed for the plan-role session. |
| Variable | `OPENTOFU_VERSION` | OpenTofu runner version. Defaults to `1.9.1`. |
| Variable | `AWS_REGION` | AWS/Bedrock region. Defaults to `us-east-1`. |
| Environment secret | `TOFU_PLAN_COMMON_TFVARS` | Exact CI copy of the ignored root `config/common.tfvars`. It is written with mode `0600` and removed after planning. |

Optional LLM explanation requires:

| Kind | Name | Purpose |
| --- | --- | --- |
| Variable | `TOFU_PLAN_POC_LLM` | Must equal `true` to invoke Bedrock. |
| Variable | `AWS_TOFU_PLAN_BEDROCK_ROLE_ARN` | Separate OIDC role with only model invocation permission. |
| Variable | `AWS_TOFU_PLAN_BEDROCK_ACCOUNT_ID` | Exact AWS account allowed for the Bedrock-role session. |
| Variable | `BEDROCK_MODEL_ID` | Model or inference profile. Defaults to `us.anthropic.claude-sonnet-4-6`. |

The two roles are deliberately separate. A Bedrock failure does not turn a successful OpenTofu
plan into a failure, and the Bedrock job never receives plan-role credentials.

Create a GitHub environment named `tofu-plan-poc` before enabling either role. During the POC it
must have required reviewers and **Prevent self-review** enabled. Both credentialed jobs reference
this environment; the automatic credential-free validation job does not and therefore never gets
`id-token: write` or waits for approval.

## AWS role boundary

The plan role must use GitHub OIDC and short-lived credentials. Its trust policy must require the
environment subject (using the actual owner/repository names):

```text
repo:OWNER/REPOSITORY:environment:tofu-plan-poc
```

Do not trust the broader `repo:OWNER/REPOSITORY:pull_request` subject for this POC. A PR can change
workflow code; binding AWS trust to the protected environment prevents that change from bypassing
the approval boundary. Do not reuse the repository's static AWS keys or any `DeployMaster` role.

For the default pilot layer, grant only:

- read access to its S3 state object and the minimum bucket listing needed by the backend;
- the DynamoDB operations required to acquire and release its state lock;
- read-only IAM calls needed to refresh the resources already in that layer;
- no create, update, delete, pass-role, state-write, secret-value, or KMS-decrypt permissions unless
  a reviewed provider/data-source requirement proves one is unavoidable.

Read-only planning is still privileged: provider code and data sources execute from the PR and can
read whatever the role can read. Therefore every job is skipped for forks, while credentialed jobs
also require protected-environment approval. A live plan is suppressed when a PR changes CI
control files, provider locks, `config.tf`, provider/backend declarations, module/provider sources,
external data sources, or provisioners. Live sanitization and LLM analysis import their code from
the PR base revision, not from the candidate checkout. Expanding the allowlist requires a fresh
permission and data-exposure review.

The workflow requests 15-minute sessions, verifies the returned AWS account, masks account IDs,
and removes its temporary profile and raw plan logs after creating the sanitized report. GitHub
Actions are pinned to full commits; the optional Bedrock client is installed from a hash-locked
requirements file.

The Bedrock role needs only the relevant `bedrock:InvokeModel` permission for the configured model
or inference profile.

## Evidence and check behavior

Each selected layer produces an artifact retained for 7 days:

```text
result.json
review.json       # live plans only
summary.md
```

The stable `POC | OpenTofu Plan` job is the future branch-protection candidate. During the POC it
should remain non-required until at least one real plan and one intentional failure have been
observed in GitHub.

The aggregate check fails when:

- discovery exceeds its safety limit;
- an expected layer result is missing;
- credential-free init or validation fails;
- live mode is enabled but no live result is produced;
- backend init, plan, or JSON projection fails;
- a downloaded result has duplicate layers or provenance metadata for another repository, commit,
  or workflow run.

OpenTofu exit code `2` is treated as a successful plan with changes. Delete/replace actions are
reported as high-severity review signals but do not yet fail the POC by policy.

## Sanitized plan contract

The reporting code reads `tofu show -json` only on the ephemeral runner. Its persisted projection
contains canonical resource addresses/types, action classes, changed top-level attribute names,
replacement attributes, output names, drift metadata, check counts, and aggregate counts. Instance
keys are replaced by a fixed marker; nested map keys are not persisted. It intentionally drops all
before/after values, variables, configuration bodies, and prior state. AWS account IDs, ARNs, and
common credential/token shapes in persisted identifiers are redacted.

The Bedrock prompt receives only this projection. Structured output is validated and rendered as
escaped Markdown. Plan content is treated as untrusted data, and the model receives no tools.

## Local verification

The core mechanics have no third-party Python dependencies:

```bash
PYTHONPATH=@bin/scripts python3 -m unittest discover \
  -s @bin/scripts/tofu_plan_ci/tests -v

actionlint .github/workflows/tofu-plan-poc.yml
```

The Bedrock runtime dependency is isolated in a human-edited
[`requirements.in`](../../@bin/scripts/tofu_plan_ci/requirements.in) and compiled to the
hash-locked [`requirements.txt`](../../@bin/scripts/tofu_plan_ci/requirements.txt). It is installed
with `--require-hashes` only by the optional analysis job.

## Residual security boundary

This remains a single `pull_request` workflow, so its YAML is itself proposed by the PR. Full-SHA
action pins, explicit `CODEOWNERS`, internal-author filtering, static-only control-plane changes,
base-revision tooling, and the protected environment reduce the risk, but the environment reviewer
is still authorizing execution of the exact candidate commit. Before live mode, enable required
code-owner review and last-push approval in branch protection, restrict allowed Actions, retain the
environment approval boundary, and create least-privilege roles. None of those external settings or
AWS resources are changed by this repository patch.

## POC exit criteria

Before broadening or making the aggregate check required:

1. Observe a credential-free PR run and verify the native summary/artifact navigation.
2. Create the protected `tofu-plan-poc` environment, provision the dedicated OIDC roles, and verify
   that both trust policies accept only its environment subject.
3. Enable one manual live plan for the pilot layer and verify that the uploaded artifact contains
   no values, account IDs, ARNs, variables, state, or plan binary.
4. Exercise a harmless plan diff and confirm OpenTofu exit code `2` remains green.
5. Exercise an intentional init/plan failure and confirm the aggregate check cannot report green.
6. Enable Bedrock, compare its explanation with the deterministic projection, and record model and
   prompt limitations.
7. Decide separately whether delete/replace signals should warn or block; the POC does not make
   that policy decision implicitly.
