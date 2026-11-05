# Decision: the plan and apply CI keep native `tofu`

| | |
| --- | --- |
| Status | Accepted, 2026-11-04 |
| Issue | [#1295](https://github.com/binbashar/le-tf-infra-aws/issues/1295) |
| Spike | [#1311](https://github.com/binbashar/le-tf-infra-aws/pull/1311) (closed without merging) |
| Evaluated | Leverage CLI 3.1.0, OpenTofu 1.13.2 |

## Decision

`tofu-plan.yml` and `tofu-apply.yml` keep calling native `tofu` through `tofu_plan_ci`
(**option 1** of #1295). Instead of switching, we:

- added [`test_leverage_parity.py`](../../@bin/scripts/tofu_plan_ci/tests/test_leverage_parity.py),
  which fails when the inputs the CI passes to OpenTofu stop matching what `leverage tofu` passes;
- put the plan's and the apply's var-file and backend resolution in one function,
  `workflow.layer_config_files`, so there is one place to keep in step;
- listed the Leverage CLI changes that would make option 2 viable (see
  [Revisit when](#revisit-when)).

We rejected **option 2** (`leverage tofu` for init, plan and apply) because the CLI's
`plan` and `apply` exit with 0 whatever OpenTofu returns, and because adopting it would
let a PR choose the binary that runs with AWS credentials. We rejected **option 3**
(importing Leverage's resolution as a library) because what it would share is a two-line
glob, and importing it means installing 30 pinned packages into a credentialed job.

## Evidence

The results come from two runs. One was local, against a throwaway Leverage project. The other was in CI, on
`apps-devstg/global/cli-test-layer` with the OIDC plan role (spike #1311, plan only, with
only exit codes and markers in the log). The CI layer had no pending changes, so cases that
need a change (exit code 2, applying a stale plan file) were tested only locally.

### Feasibility

| Question | Finding |
| --- | --- |
| Can it run without SSO? | **Not as configured.** `init`, `plan`, `apply`, `validate`, `output`, `destroy` and `force-unlock` all run authentication first. With `sso_enabled = true` (our `common.tfvars`), it exits 1 with `No AWS SSO token found`. With `sso_enabled = false`, it takes the MFA branch and exits 40, because `MFA_ENABLED` defaults to the string `"false"`, and a non-empty string is truthy (`leverage/path.py`, `modules/auth.py`). Authentication is skipped only when `MFA_ENABLED` is **empty** in `build.env`. No flag or environment variable does it. |
| Does the profile name match? | **Yes, once authentication is skipped.** The `{project}-{account}-{sso_role}` name is derived only inside the refresh step. Providers use `var.profile` from `backend.tfvars`, which is what the CI writes today. But Leverage overrides `AWS_CONFIG_FILE` and `AWS_SHARED_CREDENTIALS_FILE` with `~/.aws/<project>/…`, so the CI would have to write its OIDC session there, not where it chooses. |
| Do the extra arguments pass through? | **Yes.** `-lockfile=readonly`, `-detailed-exitcode`, `-json`, `-lock-timeout`, `-out` and a saved plan file for `apply` all reach `tofu` unchanged. The plan Leverage wrote has the same plan digest as the native plan with the same inputs. |
| Are `tofu`'s exit codes kept? | **No. This is the blocker.** `invoke_for_all_commands` drops the return code of `TFRunner.run`, so `leverage tofu plan` and `apply` exit 0 when `tofu` exits 2 (changes present), 1 (an unknown flag), or fails to apply a stale plan file. The CI cannot tell "no changes" from "changes" from "failed". The same behaviour is why the Leverage CLI test workflow reported success while every tofu command failed (#1292). |
| Is a mixed setup with native `show` acceptable? | **It works:** native `tofu show -json` reads the plan file Leverage wrote. It would still be needed. |

### Security

- **A PR could choose the binary.** Leverage reads `build.env` from the repository root down
  to the layer, and a layer-level `TF_BINARY` path is resolved against the repository. In the
  spike, a `build.env` pointing at a script committed in the PR ran in place of `tofu`, first
  for `--version` and then for `plan`, with the AWS credentials in its environment and
  credentials file. Today `build.env` means nothing to the CI, so the credential gate
  (`policy.py`) does not list it. That gate blocks every other way a PR can run code with the
  credentials: providers, lock files, `config.tf`, external data sources, provisioners. Adopting
  the CLI would open a way around it unless `build.env` were added to the gate, and the
  CLI were told to ignore `TF_BINARY` from the checkout.
- **`build.env` would also become configuration that the PR controls.** `MFA_ENABLED`, `PROJECT`
  and `TF_BINARY` change which code paths run before `tofu` starts.
- **Supply chain.** `leverage==3.1.0` pins 13 of its 14 dependencies exactly (30 packages
  once their dependencies are included). The pins include `jinja2 3.0.1`, `requests 2.31.0` and `urllib3 2.0.7`, which together carry 16
  published advisories (`pip-audit`, 2026-11-04). Because the pins are exact, we cannot raise
  them without a new CLI release. A hash-pinned install works (the spike did it), but it would
  put these versions into the job that holds the plan role and, for apply, the apply role.

### Cost and maintenance

`tofu_plan_ci` is about 3,500 lines. The CLI would replace about ten of them: the three
`-var-file=` arguments and `-backend-config=` in `workflow.py` and in `apply_workflow.py`.
The gates, the session policy, writing `common.tfvars` from the secret, the OIDC profile, the
digest, `tofu show`, redaction and reporting stay either way. The CI would gain workarounds:
it would have to blank `MFA_ENABLED`, write credentials under `~/.aws/<project>/`, pass
`--skip-validation` to `init` (layout validation can rewrite `config.tf`), and detect failure
some way other than the exit code.

### What drift is actually possible

Leverage loads every `*.tfvars` in `config/` and in `<account>/config/`, in filesystem order,
and passes `<account>/config/backend.tfvars` to `init`. The CI loads `common.tfvars`,
`account.tfvars` and `backend.tfvars`. They match today: each account's `config/` holds
exactly those two files, the repository's `config/` holds none (the CI writes `common.tfvars`
from its secret), and no variable is set in two files. The parity test checks these three
facts on every run. It also asks an installed Leverage CLI for its arguments, when one is
importable.

## Revisit when

Option 2 becomes worth another spike when the Leverage CLI:

1. **exits with OpenTofu's exit code** for `init`, `plan`, `apply` and the rest;
2. **can use credentials already in the environment**, either with a flag or an environment variable
   that skips `refresh-credentials`, and parses `MFA_ENABLED=false` as false;
3. **lets the caller fix the binary**, with an environment variable that takes precedence over
   any `build.env` `TF_BINARY`;
4. **ships with current dependency pins**, or with ranges.

Items 1 and 2 are bugs for every user of the CLI, not only for this CI. They are drafted as
issues for `binbashar/leverage`. Items 3 and 4 are needed only to run the CLI on untrusted code.
When they land, re-run the spike on #1311's branch with the new version, and drop
the workarounds above.
