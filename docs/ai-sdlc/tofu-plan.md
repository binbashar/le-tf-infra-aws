# OpenTofu pull-request plan

A native GitHub Actions check for OpenTofu changes, without Atlantis, a custom GitHub App,
automated apply, or PR comments. It started as a proof of concept (see the execution record in the
rollout runbook) and was promoted on 2026-10-11. Its scope is deliberately limited to an explicit
layer allowlist; the AWS role and report redaction are reviewed before each layer is added.

Workflow: [`.github/workflows/tofu-plan.yml`](../../.github/workflows/tofu-plan.yml).

Staged activation and rollback checklist:
[`tofu-plan-rollout.md`](tofu-plan-rollout.md).

## Current scope

- Runs on PR open, reopen, ready-for-review, and every new PR commit (`synchronize`), but only for
  non-draft, human-authored PRs whose head branch lives in this repository. Creating that branch
  requires repository write access. GitHub's event-time `author_association` is deliberately not
  used because it can remain `CONTRIBUTOR` for an internal member. Fork PRs and bot-authored PRs
  register no runner work; supporting external contributors is out of scope.
- A newer commit cancels an in-progress stale run; the cancelled run remains in Actions history.
- Detects root modules by the nearest `config.tf`, including nested layers. It does not assume an
  `account/region/layer` depth.
- Expands changes under `config/` or `<account>/config/`, but never silently truncates a scope that
  exceeds the configured `TOFU_PLAN_MAX_LAYERS` limit.
- Excludes any path with a segment ending in `--` and records why it was skipped.
- Plans only layers listed in the `TOFU_PLAN_LAYERS` repository variable (comma- or
  newline-separated; defaults to the `apps-devstg/global/cli-test-layer` integration layer, which
  stays allowlisted for testing). Add a layer only after validating its providers, data sources,
  backend, remote states, profiles, README/deployment notes, and the plan role's permissions.
- Changes to the workflow or its Python package self-test the allowlisted layers, so the
  workflow's own PR exercises more than a no-op discovery path. Those and other execution-control changes are
  always static-only and cannot reach a credentialed job.
- Runs credential-free `tofu init -backend=false -lockfile=readonly` and `tofu validate` by default.
- Runs a live backend init and speculative plan only when explicitly enabled with an OIDC role and
  approved through the protected `tofu-plan` GitHub environment.
- Uploads only sanitized JSON/Markdown reports. It never uploads the binary plan, prior state,
  variables, full UI stream, or before/after values.
- Can ask Bedrock to explain the sanitized projection. The model is advisory and cannot change the
  deterministic check result.

There is no apply path in this workflow.

## Current operating state: active

Since 2026-10-12, `TOFU_PLAN_LIVE=true` and `TOFU_PLAN_LLM=true` are the normal state. The
security boundary is environment approval, not these variables: a live plan receives AWS
credentials only after a reviewer approves the `tofu-plan` environment, and the Bedrock
explanation runs only after a separate approval of `tofu-plan-bedrock`. Both environments
require a reviewer other than the run initiator, with **Prevent self-review** and no
administrator bypass.

The two variables are kill switches. Set either to `false` to stop that stage for every PR at
once, without a workflow change, for example during an incident, a suspected credential or role
problem, or unexpected model behavior. A run reads them when it starts, so a change affects only
runs started afterwards.

What this means for each PR that touches an allowlisted layer:

- It waits for approval of `tofu-plan`, and then of `tofu-plan-bedrock`. An unapproved run keeps
  the `OpenTofu Plan` check pending; the check is not required, so it never blocks a merge. A
  waiting job uses no runner minutes, and GitHub cancels it after 30 days.
- Approving `tofu-plan-bedrock` sends the sanitized plan projection to the model. Reject it when
  the explanation is not wanted.

The model is Nova Lite (`amazon.nova-lite-v1:0`), set as `BEDROCK_MODEL_ID` on the
`tofu-plan-bedrock` environment so that it does not change the repository-wide value that
`claude.yml` reads. Nova Lite is a deliberate choice, not a constraint: the Claude inference profile
also works (see the rollout record). The check stays non-required, and each new layer goes through the onboarding steps in
[`tofu-plan-rollout.md`](tofu-plan-rollout.md).

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
| Variable | `TOFU_PLAN_LIVE` | Must equal `true` to request live planning. Normally `true`; set `false` as a kill switch. |
| Variable | `TOFU_PLAN_LAYERS` | Comma- or newline-separated layer allowlist. Defaults to `apps-devstg/global/cli-test-layer`. A manual dispatch must name its layer when several are listed. |
| Variable | `TOFU_PLAN_MAX_LAYERS` | Safety cap. Defaults to `1`. No subset is chosen when exceeded. |
| Variable | `TOFU_PLAN_ROLES` | JSON map from account directory to its plan role, e.g. `{"management": {"role_arn": "arn:aws:iam::<ID>:role/GitHubActionsOpenTofuPlan", "account_id": "<ID>"}}`. The role must be in `account_id` and must not be `DeployMaster`. A layer whose account is missing fails closed. |
| Variable | `OPENTOFU_VERSION` | OpenTofu runner version. Defaults to `1.9.1`. |
| Variable | `AWS_REGION` | AWS/Bedrock region. Defaults to `us-east-1`. |
| Environment secret | `TOFU_PLAN_COMMON_TFVARS` | Exact CI copy of the ignored root `config/common.tfvars`. It is written with mode `0600` and removed after planning. |

Optional LLM explanation requires:

| Kind | Name | Purpose |
| --- | --- | --- |
| Variable | `TOFU_PLAN_LLM` | Must equal `true` to invoke Bedrock. Normally `true`; set `false` as a kill switch. |
| Variable | `AWS_TOFU_PLAN_BEDROCK_ROLE_ARN` | Separate OIDC role with only model invocation permission. |
| Variable | `AWS_TOFU_PLAN_BEDROCK_ACCOUNT_ID` | Exact AWS account allowed for the Bedrock-role session. |
| Environment variable (`tofu-plan-bedrock`) | `BEDROCK_MODEL_ID` | Model or inference profile. Set to `amazon.nova-lite-v1:0`. Without it the job falls back to the repository variable of the same name, and then to `us.anthropic.claude-sonnet-4-6`. Keep it on the environment: `claude.yml` reads the repository variable. |

The two roles are deliberately separate. A Bedrock failure does not turn a successful OpenTofu
plan into a failure, and the Bedrock job never receives plan-role credentials or a token accepted by
the plan role.

Before enabling a credentialed role, configure each of these GitHub environments with required
reviewers, **Prevent self-review**, and administrator bypass disabled:

| Environment | Credentialed purpose | Extra configuration |
| --- | --- | --- |
| `tofu-plan` | OpenTofu plan | `TOFU_PLAN_COMMON_TFVARS` environment secret |
| `tofu-plan-bedrock` | Bedrock explanation | No OpenTofu tfvars secret |

The automatic credential-free validation job references none of these environments, so it never
gets `id-token: write` or waits for approval.

## AWS role boundary

Each role must use GitHub OIDC and short-lived credentials. Its trust policy must require the
matching environment subject (using the actual owner/repository names):

```text
plan    = repo:OWNER/REPOSITORY:environment:tofu-plan
bedrock = repo:OWNER/REPOSITORY:environment:tofu-plan-bedrock
```

Do not trust the broader `repo:OWNER/REPOSITORY:pull_request` subject. A PR can change
workflow code; binding AWS trust to the protected environment prevents that change from bypassing
the approval boundary. Do not reuse the repository's static AWS keys or any `DeployMaster` role.

Each account that hosts an allowlisted layer has one plan role, created by that account's
`<account>/global/github-oidc-tofu-plan` layer. The role's policy is the union of its layers'
needs, generated from a `plan_targets` map plus one `plan-target-<layer>.tf` file per layer. For
each allowlisted layer, grant only:

- read access to its S3 state object and the minimum bucket listing needed by the backend;
- the DynamoDB operations required to acquire and release its state lock;
- the read-only provider calls needed to refresh the resources already in that layer, derived from
  a converged local plan's CloudTrail events rather than from a managed read-only policy;
- no create, update, delete, pass-role, state-write, secret-value, or KMS-decrypt permissions unless
  a reviewed provider/data-source requirement proves one is unavoidable.

Every live job assumes its account's role with an **inline session policy** built by the trusted
base revision from the layer's backend key (`config.tf`) and the account's `backend.tfvars`. It
narrows `s3:GetObject`/`s3:ListBucket` on the state bucket and the lock-item operations on the lock
table to that one layer, and leaves every other permission to the role. An approved plan of one
layer therefore cannot read another layer's state, even though the role could.

Read-only planning is still privileged: provider code and data sources execute from the PR and can
read whatever the role can read. Therefore every job is skipped for forks, while credentialed jobs
also require protected-environment approval. A live plan is suppressed when a PR changes CI
control files, provider locks, `config.tf`, project or account configuration (`config/`,
`<account>/config/`), any OpenTofu JSON configuration, provider/backend
declarations, module/provider sources, external data sources, or provisioners. The policy scans both
native `.tf` and `.tofu` configuration before allowing a credentialed plan. Live sanitization and
LLM analysis import their code from the PR base revision, not from the candidate checkout. Expanding
the allowlist requires a fresh permission and data-exposure review.

The workflow requests 15-minute sessions, verifies the returned AWS account, masks account IDs,
and removes its temporary profile and raw plan logs after creating the sanitized report. GitHub
Actions are pinned to full commits; the optional Bedrock client is installed from a hash-locked
requirements file.

The Bedrock role needs only the relevant `bedrock:InvokeModel` permission for the configured model
or inference profile. The policy permits the configured Claude system profile and its verified
destination models, plus the exact regional `amazon.nova-lite-v1:0` fallback while its use is
being evaluated. A different variable value fails closed at IAM.

## Evidence and check behavior

Each selected layer produces an artifact retained for 7 days:

```text
result.json
review.json       # live plans only
summary.md
```

When Bedrock analysis is enabled for a supervised window, it additionally retains a 7-day
`tofu-plan-llm` artifact containing only `analysis.json` and `analysis.md`. It is derived from
the same sanitized projection and remains advisory.

The stable `OpenTofu Plan` job is the future branch-protection candidate. It remains
non-required until the promotion decisions in the rollout runbook are made.

The aggregate check fails when:

- discovery exceeds its safety limit;
- an expected layer result is missing;
- credential-free init or validation fails;
- live mode is enabled but no live result is produced;
- backend init, plan, or JSON projection fails;
- a downloaded result has duplicate layers or provenance metadata for another repository, commit,
  or workflow run.

OpenTofu exit code `2` is treated as a successful plan with changes. Delete/replace actions are
reported as high-severity review signals but do not yet fail the check by policy.

## Sanitized plan contract

The reporting code reads `tofu show -json` only on the ephemeral runner. Its persisted projection
contains canonical resource addresses/types, action classes, changed top-level attribute names,
replacement attributes, output names, drift metadata, check counts, and aggregate counts. Instance
keys are replaced by a fixed marker; nested map keys are not persisted. It intentionally drops all
before/after values, variables, configuration bodies, and prior state. AWS account IDs, ARNs, and
common credential/token shapes in persisted identifiers are redacted.

The Bedrock prompt receives only this projection. Structured output is validated and rendered as
escaped Markdown. Plan content is treated as untrusted data. Claude uses Bedrock JSON-schema
output; the exact Nova Lite fallback is forced to return the same schema as a tool input, without
any tool execution capability.

## Local verification

The core mechanics have no third-party Python dependencies:

```bash
PYTHONPATH=@bin/scripts python3 -m unittest discover \
  -s @bin/scripts/tofu_plan_ci/tests -v

actionlint .github/workflows/tofu-plan.yml
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

## Proof-of-concept exit criteria (met)

The proof of concept met these criteria before promotion; the evidence is in the rollout runbook:

1. A credential-free PR run with working native summary/artifact navigation.
2. Protected environments and dedicated OIDC roles whose trust policies accept only their own
   environment subject.
3. A manual live plan whose uploaded artifact contains no values, account IDs, ARNs, variables,
   state, or plan binary.
4. A harmless plan diff with OpenTofu exit code `2` staying green.
5. An intentional init/plan failure that the aggregate check cannot report green.
6. A Bedrock explanation compared with the deterministic projection, with model and prompt
   limitations recorded.

Still open before making the check required: whether delete/replace signals warn or block. The
workflow does not make that policy decision implicitly.
