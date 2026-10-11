# OpenTofu pull-request plan rollout

This runbook records the staged activation plan for
[`tofu-plan.yml`](../../.github/workflows/tofu-plan.yml). It deliberately separates
credential-free validation, AWS-backed planning, and LLM analysis so each trust boundary can be
tested before enabling the next one.

## Scope

- Repository: `binbashar/le-tf-infra-aws`.
- Layer allowlist (`TOFU_PLAN_LAYERS`): `apps-devstg/global/cli-test-layer`, kept as the test
  layer.
- Maximum selected layers (`TOFU_PLAN_MAX_LAYERS`): one.
- No apply, destroy, import, state mutation, PR comments, or automatic permission expansion.
- The stable PR check is `OpenTofu Plan`.
- PR automation is internal-only: same-repository, non-draft, human-authored PRs. Creating a head
  branch in the repository is the write-access boundary; the event-time `author_association` field
  is not reliable enough to enforce it. Fork and bot PRs are intentionally skipped.
- Live planning and LLM analysis remain disabled except during an explicitly supervised test
  window.

## Proof-of-concept execution record

Status observed through 2026-10-11. This record keeps the names in use at the time: the workflow
was `tofu-plan-poc.yml`, its environments `tofu-plan-poc`, `tofu-plan-poc-noop`, and
`tofu-plan-poc-bedrock`, and its variables `TOFU_PLAN_POC_*`. See
[Promotion rename](#promotion-rename-2026-10-11) for the current names.

- Gate 1 passed: discovery, credential-free initialization, validation, artifact transfer,
  provenance checks, and the aggregate check completed successfully for the pilot layer.
- Gate 2 initially configured the `tofu-plan-poc` environment. The
  `leverage-ref-architecture-aws-admin` team is its required reviewer, prevent-self-review is
  enabled, administrator bypass is disabled, and the environment-scoped
  `TOFU_PLAN_COMMON_TFVARS` secret exists. Its value is not inspectable through GitHub after it is
  set. The matching `tofu-plan-poc-noop` and `tofu-plan-poc-bedrock` environments were later
  configured with the same approval controls.
- The `master` branch requires code-owner review and approval of the last push. The workflow also
  pins every Action it references.
- Gate 3 is applied: the dedicated GitHub OIDC provider, pilot plan role, isolated no-change plan
  role, and isolated Bedrock explanation role exist in the pilot account. The workflow's
  account/session guards accepted their protected-environment sessions. The per-role environment
  trust-policy update was applied; on 2026-10-11 the identity layer planned with no changes.
- Gate 4 passed in [GitHub run 35652085092](https://github.com/binbashar/le-tf-infra-aws/actions/runs/35652085092):
  a separate environment reviewer approved the job; backend initialization, validation, and the
  speculative plan succeeded; the aggregate check passed; and only the sanitized report contract
  was retained. The plan proposed three IAM creations in the intentionally unprovisioned pilot
  layer; no apply was performed.
- Gate 5 passed for proposed change, failure, recovery, and cancellation behavior on PR #1194:
  the successful change run is the Gate 4 run above; an intentional undefined-local validation
  error failed in [run 35676588534](https://github.com/binbashar/le-tf-infra-aws/actions/runs/35676588534)
  and skipped both live planning and Bedrock; the following recovery run passed; and the
  first of two immediate commits was cancelled while its successor completed successfully.
- The no-change path passed in [GitHub run 35680389438](https://github.com/binbashar/le-tf-infra-aws/actions/runs/35680389438)
  on PR #1198. A separate, state-preserving role planned the already-converged identity layer;
  environment approval, OIDC, backend initialization, validation, sanitization, artifact transfer,
  provenance, and aggregation all succeeded with zero creates, updates, deletes, or replacements.
- Repository variables explicitly keep `TOFU_PLAN_POC_LIVE=false` and
  `TOFU_PLAN_POC_LLM=false`; the pilot layer, one-layer limit, OpenTofu version, and AWS region are
  also fixed rather than relying on workflow defaults.
- Optional Gate 6 passed in [GitHub run 35682901228](https://github.com/binbashar/le-tf-infra-aws/actions/runs/35682901228)
  on PR #1194. The live plan and the separately protected Bedrock job were each approved; the
  Bedrock-only role received only the sanitized projection and produced an advisory explanation.
  It accurately described the three IAM creates and explicitly retained uncertainty about redacted
  policy and trust values. The explanation was marked medium risk, asked useful review questions,
  did not control the aggregate result, and contained no account IDs, ARNs, or credential patterns.
- Gate 6 was revalidated with Amazon Nova Lite in
  [GitHub run 38160922117](https://github.com/binbashar/le-tf-infra-aws/actions/runs/38160922117)
  after [PR #1219](https://github.com/binbashar/le-tf-infra-aws/pull/1219) added an exact,
  invoke-only fallback permission and the maintainer applied its in-place policy update. The plan
  and Bedrock environments were approved independently. The deterministic projection reported the
  expected three IAM creates with no updates, deletes, or replacements; Nova Lite assigned medium
  risk, highlighted the IAM review questions, retained the redaction limitations, and did not
  determine the check result. Inspection of the retained, sanitized artifacts found no account-ID,
  ARN, or credential patterns.
- The supervised window is closed: `TOFU_PLAN_POC_LIVE=false` and
  `TOFU_PLAN_POC_LLM=false`. `BEDROCK_MODEL_ID` was removed, so the workflow returns to its
  documented Claude default. The exact Nova Lite permission remains as a reviewed fallback, but it
  cannot be used again without an explicit variable change, both protected-environment approvals,
  and a new supervised dispatch.

## Promotion rename (2026-10-11)

The proof of concept was promoted and every `poc` name dropped. The no-change role and its
environment were retired: nothing referenced them after the Gate 4 verification, and a converged
layer can be verified as another allowlist entry of the plan role instead.

| Kind | Proof of concept | Current |
| --- | --- | --- |
| Workflow file | `tofu-plan-poc.yml` | `tofu-plan.yml` |
| Workflow / stable check | `POC \| OpenTofu plan` / `POC \| OpenTofu Plan` | `OpenTofu plan` / `OpenTofu Plan` |
| Plan environment | `tofu-plan-poc` | `tofu-plan` |
| Bedrock environment | `tofu-plan-poc-bedrock` | `tofu-plan-bedrock` |
| No-change environment and role | `tofu-plan-poc-noop` / `GitHubActionsOpenTofuNoopPlan` | retired |
| Variables | `TOFU_PLAN_POC_LIVE`, `_LLM`, `_MAX_LAYERS` | `TOFU_PLAN_LIVE`, `TOFU_PLAN_LLM`, `TOFU_PLAN_MAX_LAYERS` |
| Layer variable | `TOFU_PLAN_POC_LAYER` (one layer) | `TOFU_PLAN_LAYERS` (comma- or newline-separated list) |
| Artifacts | `tofu-plan-poc-*` | `tofu-plan-*` |
| Docs | `tofu-plan-poc.md`, `tofu-plan-poc-rollout.md` | `tofu-plan.md`, `tofu-plan-rollout.md` |

The `AWS_TOFU_PLAN_*` variables, the `TOFU_PLAN_COMMON_TFVARS` secret, and the plan and Bedrock
IAM roles kept their names. Because the OIDC trust policies match the environment name, the
identity layer was applied with the new subjects before the rename merged; the environment secret
was re-entered in `tofu-plan`, since GitHub cannot copy a secret's value.

## Paused state and next resumption

The workflow is intentionally paused after the successful Nova Lite revalidation. It is not a
required check and no live or LLM job should be dispatched while `TOFU_PLAN_LIVE` and
`TOFU_PLAN_LLM` remain `false`.

When work resumes:

1. Recheck the Anthropic foundation-model agreement status. If it is available, set the Claude
   model explicitly for one supervised Gate 6 comparison; otherwise, explicitly reopen the
   documented Nova Lite fallback window. As of 2026-10-11 the agreement was still
   `NOT_AVAILABLE` in the pilot account (a public offer exists), so Nova Lite remains the working
   model.
2. Compare the new explanation with the deterministic projection and this Nova Lite record. Record
   usefulness, hallucinations, latency, cost, and any prompt-injection behavior before changing
   the selected model or permission set.
3. Decide whether to retain or remove the Nova Lite fallback permission in a separate reviewed
   identity-layer change. Do not broaden it to a model family or wildcard.
4. Keep the aggregate check non-required until the separate promotion decision resolves the
   destructive-change policy, state confidentiality, and incident/credential-revocation process.

## Gate 1: credential-free pull request

1. Put only the workflow implementation and documentation on a dedicated branch, open a PR, and mark it
   ready for review (draft PRs are intentionally skipped).
2. Configure these repository variables explicitly:

   ```text
   TOFU_PLAN_LIVE=false
   TOFU_PLAN_LLM=false
   TOFU_PLAN_LAYERS=apps-devstg/global/cli-test-layer
   TOFU_PLAN_MAX_LAYERS=1
   OPENTOFU_VERSION=1.9.1
   AWS_REGION=us-east-1
   ```

3. Observe the test, discovery, backend-disabled initialization, validation, and aggregate jobs.
4. Confirm that a new commit cancels the stale run and creates its own check history.
5. Inspect the summaries and credential-free artifacts before merging the workflow with live mode
   still disabled.

Exit condition: the workflow mechanics work on GitHub-hosted Linux runners without AWS
credentials, secrets, or an OIDC token.

## Gate 2: protected GitHub environment

1. Create `tofu-plan` and `tofu-plan-bedrock` before configuring an
   AWS role ARN or enabling live mode.
2. Require at least one reviewer other than the run initiator and enable **Prevent self-review** on
   each environment.
3. Do not allow protection-rule bypass on any credentialed environment.
4. Add `TOFU_PLAN_COMMON_TFVARS` to `tofu-plan` as an environment secret using the exact ignored local
   `config/common.tfvars`; do not copy it into the repository or logs.
5. Do not reuse the repository's legacy static AWS credential secrets.

Exit condition: an unapproved job cannot obtain the environment secret or progress to an OIDC
credential request.

## Security checkpoint before credentialed gates

The repository-side hardening is implemented and Gate 3 is applied, but do not enable
`TOFU_PLAN_LIVE` until the external controls below are configured or their residual risk is
explicitly accepted. Verify that:

- fork, draft, and bot PRs skip all jobs; only branches pushed to the original repository are in
  scope, and a protected-environment reviewer makes a fresh decision for the exact internal commit
  that will receive a live plan;
- refuse credentialed execution when the PR changes this workflow, its reporting/analyzer code,
  action definitions, provider selections, dependency locks, or other execution-control files;
- run sanitization and LLM rendering from a trusted revision rather than importing those programs
  from the PR under review;
- pin every referenced GitHub Action to a reviewed full commit SHA and lock Python dependencies
  with hashes or remove the runtime install;
- shorten the AWS session, assert the expected account, mask account identifiers, and remove the
  temporary credential files immediately after use;
- canonicalize or hash arbitrary instance keys and changed map keys, and test redaction against
  high-entropy tokens and other generic secret shapes rather than only AWS account IDs and ARNs;
- explicit CODEOWNERS entries protect the workflow and its scripts, and branch protection actually
  requires code-owner review plus approval of the last push;
- document that OpenTofu configuration, providers, modules, and data sources can execute code or
  disclose any state, variables, and credentials available to the planning process. Environment
  approval is therefore authorization to execute that exact PR commit, not merely approval to view
  a harmless diff.

Exit condition: the security review accepts the remaining risk for same-repository contributions;
forks remain completely unsupported and skipped.

## Gate 3: dedicated AWS bootstrap

1. Check the `apps-devstg` account for an existing IAM OIDC provider for
   `https://token.actions.githubusercontent.com`; reference or import an owned provider rather than
   creating a duplicate.
2. Prefer a dedicated `apps-devstg/global/github-actions-opentofu` root module over adding the plan
   identities to the broad `base-identities` lifecycle.
3. Create separate plan and Bedrock-explanation roles. Each trust must
   require the audience and its matching environment subject:

   ```text
   aud = sts.amazonaws.com
   plan sub    = repo:binbashar/le-tf-infra-aws:environment:tofu-plan
   bedrock sub = repo:binbashar/le-tf-infra-aws:environment:tofu-plan-bedrock
   ```

4. Limit each plan role to its own state object's S3 reads, exact DynamoDB lock keys, caller
   identity, and only the IAM reads required to refresh its layer.
5. Do not grant state-object writes, resource mutation, `iam:PassRole`, secret reads, or unrelated
   KMS permissions. Stop rather than expanding into one of these classes on the first failure.
6. Plan, review, and apply this bootstrap through the repository's normal maintainer-operated
   process. The workflow must not bootstrap its own identity.

Exit condition: each dedicated role can be assumed only through its own protected environment and
has no infrastructure mutation path.

## Gate 4: one supervised live plan

1. Set `AWS_TOFU_PLAN_ROLE_ARN` and `AWS_TOFU_PLAN_ACCOUNT_ID`, leave
   `TOFU_PLAN_LLM=false`, and temporarily set `TOFU_PLAN_LIVE=true`.
2. Dispatch the workflow manually on `master` and have a different reviewer approve the protected
   job.
3. Confirm that the final check is deterministic and that the artifact contains only
   `result.json`, `review.json`, and `summary.md`.
4. Inspect those files for state, variables, before/after values, account IDs, ARNs, generic secret
   material, and a binary plan. Treat any occurrence as a stop condition.
5. Return `TOFU_PLAN_LIVE=false` after the run.
6. If the role receives `AccessDenied`, add only a demonstrated read or exact lock permission. Do
   not grant state writes or broad managed policies to make the test pass.

Exit condition: one no-op or current-state plan completes and persists only the reviewed sanitized
contract. This was satisfied by run 35680389438.

## Gate 5: commit-by-commit behavior

1. Open a disposable PR with an innocuous proposed tag change in the test layer; never apply or
   merge the test change.
2. Enable live mode only for the supervised test window and verify that exit code `2` produces a
   successful check with an accurate change summary.
3. Add a temporary validation error in a new commit and verify that the aggregate check cannot
   report success or proceed to the credentialed plan.
4. Revert the error in another commit and verify that every commit has its own retained run while
   stale in-progress work is cancelled.
5. Disable live mode and close or revert the disposable change.

Exit condition: no-change, proposed-change, failure, cancellation, and recovery behavior have all
been observed without applying infrastructure.

## Optional Gate 6: Bedrock explanation

1. Manually inspect the first sanitized plan artifact before sending the same schema to a model.
2. Confirm the accepted data-residency boundary for the selected Bedrock model or inference
   profile.
3. Create a second OIDC role with only the exact model-invocation resources required by that
   profile.
4. Configure `AWS_TOFU_PLAN_BEDROCK_ROLE_ARN`, `AWS_TOFU_PLAN_BEDROCK_ACCOUNT_ID`, and
   `BEDROCK_MODEL_ID`, then temporarily enable `TOFU_PLAN_LLM=true` for one supervised run.
5. Compare the model explanation to the deterministic projection. Record hallucinations,
   omissions, prompt-injection behavior, cost, and latency; the model must never determine the
   check result.
6. Disable LLM mode after the test window.

### Temporary Nova Lite fallback

If an Anthropic account agreement delays the selected Claude profile, use
`amazon.nova-lite-v1:0` only as a reviewed, reversible fallback:

1. Apply the identity-layer policy update that permits precisely that regional foundation-model
   ARN; do not generalize the policy to a model family or wildcard.
2. Set `BEDROCK_MODEL_ID=amazon.nova-lite-v1:0` after the policy is applied. The analyzer selects
   Nova's forced tool-call structured-output path only for that exact ID.
3. Run one supervised Gate 6 window, compare its explanation with the deterministic projection,
   and return `TOFU_PLAN_LLM=false` afterward.
4. Once the Anthropic agreement is available, either restore the profile variable and remove the
   Nova permission in a reviewed change, or explicitly retain it with documented evaluation
   evidence.

Exit condition: the explanation is useful, remains advisory, and does not expand the data or
permission boundary. This was satisfied by run 35682901228; retain its stated limitations when
evaluating future explanations.

## Promotion decision

Do not make the check required or expand the layer allowlist until all applicable gates pass and a
separate security review accepts the residual risk of running OpenTofu configuration proposed by a
PR author. Decide destructive-change policy, state confidentiality, and
incident/credential-revocation procedures before promotion. External-contributor support remains a
future, separately designed feature rather than an implicit extension of this workflow.
