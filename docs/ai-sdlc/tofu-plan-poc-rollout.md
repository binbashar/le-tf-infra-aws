# OpenTofu pull-request plan POC rollout

This runbook records the staged activation plan for
[`tofu-plan-poc.yml`](../../.github/workflows/tofu-plan-poc.yml). It deliberately separates
credential-free validation, AWS-backed planning, and LLM analysis so each trust boundary can be
tested before enabling the next one.

## Fixed POC scope

- Repository: `binbashar/le-tf-infra-aws`.
- Pilot layer: `apps-devstg/global/cli-test-layer`.
- Maximum selected layers: one.
- No apply, destroy, import, state mutation, PR comments, or automatic permission expansion.
- The stable PR check is `POC | OpenTofu Plan`.
- PR automation is internal-only: same-repository, non-draft, human-authored PRs. Creating a head
  branch in the repository is the write-access boundary; the event-time `author_association` field
  is not reliable enough to enforce it. Fork and bot PRs are intentionally skipped.
- Live planning and LLM analysis remain disabled except during an explicitly supervised test
  window.

## Gate 1: credential-free pull request

1. Put only the POC implementation and documentation on a dedicated branch, open a PR, and mark it
   ready for review (draft PRs are intentionally skipped).
2. Configure these repository variables explicitly:

   ```text
   TOFU_PLAN_POC_LIVE=false
   TOFU_PLAN_POC_LLM=false
   TOFU_PLAN_POC_LAYER=apps-devstg/global/cli-test-layer
   TOFU_PLAN_POC_MAX_LAYERS=1
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

1. Create the `tofu-plan-poc` environment before configuring an AWS role ARN or enabling live
   mode.
2. Require at least one reviewer other than the run initiator and enable **Prevent self-review**.
3. Do not allow protection-rule bypass during the POC.
4. Add `TOFU_PLAN_COMMON_TFVARS` as an environment secret using the exact ignored local
   `config/common.tfvars`; do not copy it into the repository or logs.
5. Do not reuse the repository's legacy static AWS credential secrets.

Exit condition: an unapproved job cannot obtain the environment secret or progress to an OIDC
credential request.

## Security checkpoint before credentialed gates

The repository-side hardening is implemented, but do not enable `TOFU_PLAN_POC_LIVE` or configure
a usable role ARN until it has been reviewed and its external controls are configured. Verify that:

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
- explicit CODEOWNERS entries protect the workflow and POC scripts, and branch protection actually
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
2. Prefer a dedicated `apps-devstg/global/github-actions-tofu-plan` root module over adding the POC
   identities to the broad `base-identities` lifecycle.
3. Create separate plan and Bedrock roles. Their trust must require both:

   ```text
   aud = sts.amazonaws.com
   sub = repo:binbashar/le-tf-infra-aws:environment:tofu-plan-poc
   ```

4. Limit the plan role to the pilot state object's S3 reads, its exact DynamoDB lock keys, caller
   identity, and the IAM reads required to refresh `LeverageTest` and `leverage_test`.
5. Do not grant state-object writes, resource mutation, `iam:PassRole`, secret reads, or unrelated
   KMS permissions. Stop rather than expanding into one of these classes on the first failure.
6. Plan, review, and apply this bootstrap through the repository's normal maintainer-operated
   process. The POC must not bootstrap its own identity.

Exit condition: the dedicated role can be assumed only through the protected environment and has
no infrastructure mutation path.

## Gate 4: one supervised live plan

1. Set `AWS_TOFU_PLAN_ROLE_ARN` and `AWS_TOFU_PLAN_ACCOUNT_ID`, leave
   `TOFU_PLAN_POC_LLM=false`, and temporarily set `TOFU_PLAN_POC_LIVE=true`.
2. Dispatch the workflow manually on `master` and have a different reviewer approve the protected
   job.
3. Confirm that the final check is deterministic and that the artifact contains only
   `result.json`, `review.json`, and `summary.md`.
4. Inspect those files for state, variables, before/after values, account IDs, ARNs, generic secret
   material, and a binary plan. Treat any occurrence as a stop condition.
5. Return `TOFU_PLAN_POC_LIVE=false` after the run.
6. If the role receives `AccessDenied`, add only a demonstrated read or exact lock permission. Do
   not grant state writes or broad managed policies to make the test pass.

Exit condition: one no-op or current-state plan completes and persists only the reviewed sanitized
contract.

## Gate 5: commit-by-commit behavior

1. Open a disposable PR with an innocuous proposed tag change in the pilot layer; never apply or
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
   `BEDROCK_MODEL_ID`, then temporarily enable `TOFU_PLAN_POC_LLM=true` for one supervised run.
5. Compare the model explanation to the deterministic projection. Record hallucinations,
   omissions, prompt-injection behavior, cost, and latency; the model must never determine the
   check result.
6. Disable LLM mode after the test window.

Exit condition: the explanation is useful, remains advisory, and does not expand the data or
permission boundary.

## Promotion decision

Do not make the check required or expand the layer allowlist until all applicable gates pass and a
separate security review accepts the residual risk of running OpenTofu configuration proposed by a
PR author. Decide destructive-change policy, state confidentiality, and
incident/credential-revocation procedures before promotion. External-contributor support remains a
future, separately designed feature rather than an implicit extension of this POC.
