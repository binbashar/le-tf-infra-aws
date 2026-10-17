# OpenTofu CI: incident and credential revocation

What to do when the OpenTofu PR workflow, or one of its AWS identities, may have been misused. It
covers the plan stage that runs today ([`tofu-plan.md`](tofu-plan.md)) and the apply stage that is
being designed. Having this procedure documented and rehearsed is a prerequisite for creating any
write role and for making the check required.

Status (2026-10-17): **rehearsed once on apps-devstg** ([record](tofu-plan-history.md#incident-procedure-rehearsal)).
Not yet rehearsed for an apply role.

## 1. When to use it

Start this procedure on any of these, without waiting for confirmation:

- A `tofu-plan` (or later `tofu-apply`) run did something nobody expected: an unknown layer,
  an unexpected commit, or an approval nobody remembers giving.
- A PR that ran with credentials turns out to carry malicious provider, module, or
  `external` data source code.
- CloudTrail shows a `GitHubActionsOpenTofu*` session calling an API outside its usual pattern,
  or a session whose name does not match a run in this repository.
- A secret of the `tofu-plan` environment, or a maintainer's GitHub account, may be compromised.
- Bedrock spend for the explainer role jumps with no matching PR activity.

Anyone on `leverage-ref-architecture-aws-admin` may contain (§3). Recovery (§6) needs two people.

## 2. What can be exposed

| Identity or secret | Where | What it can do | Lifetime |
| --- | --- | --- | --- |
| `GitHubActionsOpenTofuPlan` role | apps-devstg, management | Read the allowlisted layers' resources and state, and take their state lock. Each job's session policy narrows it to one layer | Sessions of 900 s requested; role allows up to 3600 s |
| `GitHubActionsOpenTofuBedrock` role | apps-devstg | Invoke Haiku 5.5 and Nova Lite only | Same |
| `GitHubActionsOpenTofuApply` role (planned) | per account | Write the allowlisted layers' resources and state | Same |
| `TOFU_PLAN_COMMON_TFVARS` | env `tofu-plan` secret | Copy of `config/common.tfvars`: account IDs and SSO configuration. Not a credential, but it must not be published | Until rotated |
| `TOFU_PLAN_DIGEST_KEY` | env `tofu-plan` secret | Keys the plan digest. A leak lets someone brute-force low-entropy values from a public digest, not forge an apply | Until rotated |
| `GITHUB_TOKEN` | every job | Scoped by the job's `permissions` | Expires when the job ends |

The roles trust only `repo:binbashar/le-tf-infra-aws:environment:tofu-plan` (the apply role will
trust `tofu-apply`), from `master` or a PR merge ref, through the account's GitHub OIDC provider.
There are no long-lived AWS keys to rotate.

## 3. Contain (first 15 minutes)

Do the steps in order. Each one is safe to run even if the next turns out to be unnecessary.

**1. Stop new runs.** This takes effect immediately for every PR:

```bash
gh workflow disable tofu-plan.yml            # later also: tofu-apply.yml
gh run list --workflow tofu-plan.yml --status in_progress --json databaseId --jq '.[].databaseId' \
  | xargs -n1 gh run cancel
gh run list --workflow tofu-plan.yml --status waiting --json databaseId --jq '.[].databaseId' \
  | xargs -n1 gh run cancel
```

Setting `TOFU_PLAN_LIVE=false` is not enough on its own: a run reads its variables when it starts.

**2. Deny the roles in AWS.** An explicit deny is evaluated on every request, so it cuts off
sessions that already exist, not only new ones. Run this in each affected account, with an SSO
profile that can write IAM:

```bash
for role in GitHubActionsOpenTofuPlan GitHubActionsOpenTofuBedrock; do   # only the roles in that account
  aws iam put-role-policy --profile <ADMIN_PROFILE> --role-name "$role" \
    --policy-name IncidentDenyAll \
    --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"*","Resource":"*"}]}'
done
```

The layers do not manage inline policies, so `tofu` neither shows nor removes `IncidentDenyAll`.
It stays in place until someone removes it by hand (§6).

`AssumeRoleWithWebIdentity` and `GetCallerIdentity` still succeed, which is expected: the first
call is evaluated against the trust policy, and IAM cannot deny the second. Every other call is
denied, and a live plan fails at `init`.

**3. Revoke the sessions issued so far.** This step is for later: when `IncidentDenyAll` is
removed, sessions issued before the incident would otherwise become valid again for up to an hour.
It is the same policy the console's "Revoke active sessions" button writes:

```bash
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
aws iam put-role-policy --profile <ADMIN_PROFILE> --role-name "<ROLE>" \
  --policy-name AWSRevokeOlderSessions \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Deny\",\"Action\":\"*\",\"Resource\":\"*\",\"Condition\":{\"DateLessThan\":{\"aws:TokenIssueTime\":\"$NOW\"}}}]}"
```

**4. Rotate exposed secrets** if they may have leaked:

```bash
openssl rand -hex 32 | tr -d '\n' | gh secret set TOFU_PLAN_DIGEST_KEY --env tofu-plan
```

Rotating the digest key invalidates every reviewed plan. Pending applies must plan again, which is
the intended effect. `TOFU_PLAN_COMMON_TFVARS` holds configuration rather than credentials: replace
it only if its contents changed, but record any leak.

**5. Apply stage only:** do **not** release layer locks (`refs/tofu-locks/*`). They show which
layers a run may have changed and keep other PRs from applying on top.

**6. Say so.** Post in the team channel what was disabled and when, and who is handling it.

Do not delete the roles or the OIDC provider. The deny already stops them, deleting them destroys
evidence, and the OIDC provider is shared with other workflows (`prevent_destroy`).

## 4. Investigate

Every session name contains the GitHub run ID (`tofu-plan-<run_id>`, `tofu-plan-llm-<run_id>`),
so each AWS session maps to exactly one run.

- **AWS:** look for `AssumeRoleWithWebIdentity` on `GitHubActionsOpenTofu*` roles in the window,
  then follow each session's access key (`responseElements.credentials.accessKeyId`) through its
  events. The account's Event history is enough for a first pass:
  `aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity`.
  It holds management events only, though. State reads and writes in S3 are data events, which
  are only visible in the organization trail (`security/us-east-1/security-audit`) when data
  events are enabled there. For the apply role, list every write event: that is the
  set of changes to verify or undo.
- **GitHub:** review the run's logs and jobs, who approved the `tofu-plan` or `tofu-apply`
  deployment and on which commit, and the PR diff at that commit. In the organization audit log,
  look for changes to environments, secrets, variables, branch protection, and workflows.
- **State (apply stage):** the backend buckets are versioned. Compare the state version written by
  the run with the one before it to see what was recorded.
- **Bedrock:** check invocation metrics for the role in apps-devstg against the runs in the window.

Record the timeline, affected runs, sessions, and findings in
[`tofu-plan-history.md`](tofu-plan-history.md), with identifiers redacted as for plan output
(`@bin/scripts/redact_plan.py --scan` before committing).

## 5. Fix the cause

Typical fixes: revert or close the malicious PR; remove a compromised account from the team and the
organization; tighten the trust, session policy, or gate that let it through. Apply stage: undo
unwanted infrastructure changes with a reviewed PR that a maintainer applies **locally**. The
workflow stays disabled until §6.

## 6. Recover

Two people: one does the steps, the other checks them.

1. Merge the fix, and apply any identity layer change locally (`leverage tofu apply`).
2. Keep `AWSRevokeOlderSessions` in place and remove `IncidentDenyAll`:
   `aws iam delete-role-policy --role-name <ROLE> --policy-name IncidentDenyAll`.
3. Enable the workflow: `gh workflow enable tofu-plan.yml`.
4. Run a supervised dispatch on `apps-devstg/global/cli-test-layer` and confirm it passes.
5. After 24 hours, which is longer than the maximum session, remove `AWSRevokeOlderSessions`.
6. Close the entry in `tofu-plan-history.md`, including what changed to prevent a repeat.

## 7. Prevention notes

- Approving `tofu-plan` runs the PR's code with read access. Approving `tofu-apply` will run it
  with write access. Approve only after reading the diff, including providers, modules, and data
  sources.
- `max_session_duration` cannot go below 3600 s, which is the IAM minimum. The workflow requests
  900 s.
- A Bedrock spend alarm and a cost cap are open roadmap items that would turn the last trigger in
  §1 into an alert.

## 8. Rehearsal

Phase 2 of the apply plan is complete when this has been done once on apps-devstg and recorded in
`tofu-plan-history.md`:

1. Put `IncidentDenyAll` on `GitHubActionsOpenTofuPlan`.
2. Dispatch `tofu-plan` on `cli-test-layer` and confirm the live plan fails at `init`.
3. Disable and re-enable the workflow, and confirm a dispatch is refused while disabled.
4. Follow §6 steps 2 to 5, then confirm a dispatch passes.
5. Find the drill's sessions in the organization trail by their session names.

Repeat it whenever a new role type is added, the first time being the apply role.
