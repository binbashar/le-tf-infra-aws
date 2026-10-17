# OpenTofu pull-request plan: history

Record of how [the workflow](tofu-plan.md) was rolled out, with evidence and decisions. Not
needed to operate it. Add new entries at the end of the relevant section.

## Timeline

| Date | Event | Evidence |
| --- | --- | --- |
| 2026-09 | Proof of concept (`tofu-plan-poc.yml`) passes Gates 1–6 on `apps-devstg/global/cli-test-layer` | [Gates](#rollout-gates) |
| 2026-10-11 | Gate 6 revalidated with Nova Lite (Claude agreement reported `NOT_AVAILABLE`) | [run 38160922117](https://github.com/binbashar/le-tf-infra-aws/actions/runs/38160922117), PR #1219 |
| 2026-10-11 | Promoted out of POC; `poc` dropped from every name; no-change role retired | PR #1222, [rename](#promotion-rename) |
| 2026-10-11 | Per-account roles and per-layer session policy; `management/global/sso` onboarded | PRs #1223, #1225, #1226, [record](#management-sso-onboarding) |
| 2026-10-12 | Active by default: `TOFU_PLAN_LIVE`/`TOFU_PLAN_LLM` become kill switches | PR #1229, [decisions](#decisions) |
| 2026-10-12 | First real change planned and explained in CI (`finops-agent:*` for DevOps) | PR #1228, [run 38194574887](https://github.com/binbashar/le-tf-infra-aws/actions/runs/38194574887) |
| 2026-10-12 | Haiku 5.5 replaces Sonnet 4.6; Nova Lite kept as the second model | PR #1235, [run 38310871272](https://github.com/binbashar/le-tf-infra-aws/actions/runs/38310871272) |
| 2026-10-12 | Explainer and security review of the redacted plan text run inside the plan job; first CI run on `cli-test-layer` found the `vpc:*` wildcard and the account-root trust | PR #1237, [run 38331108509](https://github.com/binbashar/le-tf-infra-aws/actions/runs/38331108509) |
| 2026-10-12 | `TOFU_PLAN_MAX_LAYERS` applies only to live-eligible runs. With two allowlisted layers, every PR touching the workflow code self-tested both and was blocked by the cap of 1; `OpenTofu Plan` failed on #1235 and #1237 unnoticed (the check is not required) | PR #1238 |
| 2026-10-12 | Bedrock role stops trusting `tofu-plan-bedrock`; after the apply, the environment and `TOFU_PLAN_LLM` are deleted | PR #1238 |
| 2026-10-16 | Atlantis POC config removed; plan result gains a keyed `plan_digest` | PRs #1244, #1245 |
| 2026-10-17 | Incident and credential-revocation procedure rehearsed on apps-devstg | PR #1246, [record](#incident-procedure-rehearsal) |
| 2026-10-17 | Apply-before-merge: apps-devstg apply role, `tofu-apply` environment, `/tofu apply` workflow | PRs #1247, #1248 |
| 2026-10-17 | First CI apply (`cli-test-layer`, 3 creates); all eight supervised cases pass | PRs #1249–#1253, [record](#apply-supervised-test) |

## Rollout gates

The POC enabled one trust boundary at a time. Names below are the POC names (`tofu-plan-poc*`).

| Gate | Goal | Result |
| --- | --- | --- |
| 1. Credential-free PR | Discovery, validation, artifacts, and the aggregate check work without AWS access | Passed |
| 2. Protected environment | No secret or OIDC token before approval; reviewer team `leverage-ref-architecture-aws-admin`, Prevent self-review, no admin bypass | Passed |
| Security checkpoint | Fork/bot skip, control-plane changes static-only, base-revision tooling, pinned Actions, hash-locked deps, short sessions, redaction tests, CODEOWNERS, code-owner + last-push approval on `master` | Accepted |
| 3. AWS bootstrap | Dedicated OIDC provider and roles in apps-devstg, environment-bound trust, no mutation path | Applied |
| 4. Supervised live plan | Only the sanitized contract persists | [run 35652085092](https://github.com/binbashar/le-tf-infra-aws/actions/runs/35652085092); no-change path [run 35680389438](https://github.com/binbashar/le-tf-infra-aws/actions/runs/35680389438) |
| 5. Commit-by-commit | Change (exit 2 stays green), failure ([run 35676588534](https://github.com/binbashar/le-tf-infra-aws/actions/runs/35676588534)), recovery, cancellation | Passed on PR #1194 |
| 6. Bedrock explanation | Advisory, accurate, no data leak | Claude: [run 35682901228](https://github.com/binbashar/le-tf-infra-aws/actions/runs/35682901228); Nova Lite: [run 38160922117](https://github.com/binbashar/le-tf-infra-aws/actions/runs/38160922117) |

Both explanations described the three planned IAM creations accurately, rated them medium risk,
kept the redaction limits explicit, and held no account IDs, ARNs, or credentials. The detailed
gate procedures are in the git history of the former `tofu-plan-rollout.md`.

## Promotion rename

| Kind | POC | Current |
| --- | --- | --- |
| Workflow file / check | `tofu-plan-poc.yml` / `POC \| OpenTofu Plan` | `tofu-plan.yml` / `OpenTofu Plan` |
| Environments | `tofu-plan-poc`, `tofu-plan-poc-bedrock`, `tofu-plan-poc-noop` | `tofu-plan`, `tofu-plan-bedrock` (retired 2026-10-12, #1238), noop retired |
| Variables | `TOFU_PLAN_POC_LIVE`, `_LLM`, `_MAX_LAYERS`, `_LAYER` | `TOFU_PLAN_LIVE`, `_LLM`, `_MAX_LAYERS`, `TOFU_PLAN_LAYERS` (list) |
| Artifacts / docs | `tofu-plan-poc-*` / `tofu-plan-poc*.md` | `tofu-plan-*` / `tofu-plan.md` |

The OIDC trust matches the environment name, so the identity layer was applied with the new
subjects before the rename merged, and the tfvars secret was re-entered in the new environment.

## Management SSO onboarding

PR #1223 replaced the single plan role with one role per account (`TOFU_PLAN_ROLES`) and a
per-job session policy, renamed the apps-devstg identity layer to `github-oidc-tofu-plan`
(state migrated, then the old object deleted), and created the first GitHub OIDC provider in
management. The supervised dispatch needed three runs:

| Run | Result | Cause | Fix |
| --- | --- | --- | --- |
| [38191968886](https://github.com/binbashar/le-tf-infra-aws/actions/runs/38191968886) | Validation failed | Lock file had no `linux_amd64` `h1:` hash for `hashicorp/aws`; passed on macOS | #1225 |
| [38192501713](https://github.com/binbashar/le-tf-infra-aws/actions/runs/38192501713) | `sso:ListTagsForResource` denied | Granted on instance, permission sets, and accounts, not applications | #1226 |
| [38192953426](https://github.com/binbashar/le-tf-infra-aws/actions/runs/38192953426) | Passed, 0 changes | | |

The artifacts held no e-mail addresses or Identity Center IDs. Both lessons are now steps 1 and 2
of [Adding a layer](tofu-plan.md#adding-a-layer).

## Incident procedure rehearsal

On 2026-10-17, the [incident procedure](tofu-ci-incident.md) was rehearsed on the apps-devstg plan
role. One maintainer ran the IAM writes with `bb-apps-devstg-devops`, and Claude Code ran the
dispatches and checks.

| Time (UTC) | Step | Result |
| --- | --- | --- |
| 04:02:51 | `IncidentDenyAll` on `GitHubActionsOpenTofuPlan` | Applied |
| 04:05 | Dispatch [39001184626](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39001184626) | `AssumeRoleWithWebIdentity` succeeded; live plan failed at `init` with no plan digest; check red |
| 04:05:52 | Disable workflow, dispatch, enable | Dispatch refused: `HTTP 422: Cannot trigger a 'workflow_dispatch' on a disabled workflow` |
| 04:07:10 | `AWSRevokeOlderSessions` (`aws:TokenIssueTime` < 04:07:10) | Applied |
| 04:07:28 | `IncidentDenyAll` removed | Role has only the revoke policy |
| 04:08 | Dispatch [39001391540](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39001391540) | Passed, 3 creates. Same `plan_digest` as run 38994289204 on the same commit and state |
| — | CloudTrail Event history | `tofu-plan-39001184626` found by session name; its key made only `GetCallerIdentity` calls |
| pending | Remove `AWSRevokeOlderSessions` | Due after 2026-10-18 04:07 UTC |

Lessons, folded into the procedure:

- The deny does not block `AssumeRoleWithWebIdentity`, because that call is evaluated against the
  trust policy, nor `GetCallerIdentity`, which IAM cannot deny. Both succeed; everything else is
  denied.
- The live plan reports `stage: init` with no denied action: the S3 backend error does not use the
  "not authorized to perform" wording that the diagnostic extracts.
- The account's Event history holds management events only. The S3 state reads are data events, so
  following them needs the organization trail with data events enabled.
- Long commands pasted from the terminal wrapped onto several lines and failed. Commands meant to
  be pasted must fit on one line or live in a script.
- Two runs on the same commit and state produced the same `plan_digest` in CI.

## Apply supervised test

On 2026-10-17, phase 5 of [`tofu-apply.md`](tofu-apply.md#8-phases) ran on
`apps-devstg/global/cli-test-layer`. `diego-ojeda-binbash` authored the PRs and posted the
commands, and `binbashdevops` approved the PRs and both environments.

| # | Case | PR | Run | Result |
| --- | --- | --- | --- | --- |
| 1a | `/tofu apply` before the PR was approved | #1249 | [39045722080](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39045722080) | ⛔ "no approving review on the current head commit…"; no lock, no approval requested |
| 1b | `/tofu apply --force` | #1249 | [39045829847](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39045829847) | ⛔ "unsupported flag --force" |
| 2 | Create | #1249 | [39045971132](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39045971132) | ✅ 3 added. Status `OpenTofu Apply` went from pending to success; lock tag recorded PR, head, and run. AWS evaluates `job_workflow_ref` in the trust |
| — | First plan of the provisioned layer | #1250 | [39046115733](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39046115733) | Plan failed: `iam:ListRolePolicies` denied for the plan role. Fixed by #1251 |
| 3 | Lock conflict | #1250 | [39046949041](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39046949041) | ⛔ "locked by #1249"; `lock` and `apply` skipped |
| 4 | Merge releases the lock | #1249 | [39047144958](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39047144958) | Lock deleted |
| 5 | Update (tag the policy) | #1250 | [39047647296](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39047647296) | ✅ 1 changed |
| 6 | Manual tag added after review | #1252 | [39057306825](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39057306825) | ⛔ "the plan changed since it was reviewed"; the run's own lock released. After close and reopen and a new plan, [39057592666](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39057592666): ✅ 1 changed, manual tag removed |
| 8 | Closed without merging after the apply | #1252 | [39057732940](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39057732940), [39057802433](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39057802433) | Lock kept with a comment; `/tofu unlock` on the closed PR released it after the environment approval |
| 7 | Destroy (`provisioned = false`) | #1253 | [39058229444](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39058229444), [39058288047](https://github.com/binbashar/le-tf-infra-aws/actions/runs/39058288047) | ⛔ without `--allow-destroy`; ✅ 3 destroyed with it. Merge released the lock; `master` and AWS match |

Lessons:

- **Strict up-to-date has a cost.** Every merge to `master` meant updating the other PR's branch,
  waiting for a new plan, and approving the new head again (#1250 went through it twice).
  It is still strict; revisit it with real traffic.
- **Commands are not queued behind a plan.** `/tofu apply` posted while the new head's plan was
  still running was rejected ("has not finished"). That is correct, but easy to trip on.
- **Close and reopen re-plans the same head without a new approval.** That is how case 6 recovered.
- **A layer that was never provisioned hides missing plan reads.** The plan role only failed on the
  first refresh of existing resources. The apply role already had the read.
- **Post-create drift is noise.** The first refresh after a create reports drift on
  `managed_policy_arns` and `tags`, which are not external changes.
- **Least privilege shapes the tests.** Changing `aws_iam_policy.description` forces a replacement,
  so the update case tags the policy instead. And because the apply role can only touch
  `LeverageTest` and `leverage_test`, the destroy case tears the layer down rather than deleting a
  throwaway resource.
- **The close comment printed the lock slug.** It now prints the layer path.

## Decisions

| Date | Decision | Why |
| --- | --- | --- |
| 2026-10-11 | One role per account with a per-layer session policy, not one role per layer | Fewer roles and OIDC trusts to manage; the session policy still isolates state per layer. |
| 2026-10-11 | Keep `cli-test-layer` allowlisted | Integration layer for testing workflow changes. |
| 2026-10-11 | Onboard `management/global/sso`, accepting that the role can read Identity Center users and e-mail addresses | Most frequently changed layer (onboarding, offboarding, group permissions). |
| 2026-10-11 | Name the identity layers `github-oidc-tofu-plan` | Describes provider and purpose; consistent across accounts. |
| 2026-10-12 | Live plan and Bedrock on by default; variables only as kill switches | Environment approval is the real control; toggling added steps without adding a control, and a run reads variables only at start. |
| 2026-10-12 | Keep Nova Lite, set on the `tofu-plan-bedrock` environment | Maintainer choice for now. The Claude profile does work: the #1228 run used it (started before the environment variable existed) although `get-foundation-model-availability` still reported `agreementAvailability: NOT_AVAILABLE`, so that field is not a usability signal. |
| 2026-10-12 | Merge the two docs into a reference doc plus this history | The rollout runbook mixed live procedures with history and had drifted from the current state. |
| 2026-10-12 | Replace Claude Sonnet 4.6 with Claude Haiku 5.5; keep Nova Lite as the switchable second model | Haiku 5.5 costs $0.10 / $0.50 per million tokens. On the #1228 projection it named the affected resource type, the missing values, and concrete review questions, while Nova Lite produced two generic lines and rated it low risk. Haiku 5.5 does not support Bedrock structured outputs and rejects `temperature`, so both models answer through a forced tool call and the analyzer keeps a per-model registry; Haiku runs with adaptive thinking disabled (5 s instead of 11 s, ~30% fewer output tokens). |
| 2026-10-12 | Replace the explanation of the value-free projection with two analyses of the redacted plan text: an explainer and a security review | The projection hides values, so explanations were generic. On the #1228 plan text, Haiku 5.5 named the exact change (`finops-agent:*` added to DevOps and DevOpsPrd) and flagged the wildcard grant with evidence and a recommendation, for ~$0.001 per commit for both. |
| 2026-10-17 | `cli-test-layer` converges with no resources (`local.provisioned = false`) instead of staying unprovisioned with a standing plan of three creates | With apply-before-merge, `master` and the infrastructure must match. A test that needs resources sets `provisioned = true` in a PR and applies it. |
| 2026-10-12 | Run both analyses inside the plan job (one approval), with the central apps-devstg Bedrock role trusting `tofu-plan`; a kill switch per analysis; no analysis above ~80K estimated tokens; sso e-mails may reach Bedrock | The raw plan cannot travel as an artifact in a public repository. The e-mails are already in the public sso code. The token cap keeps Haiku 5.5 under its 100K-token price tier. Keeping the second approval would have required an S3 handoff and a write permission on the plan role. |
