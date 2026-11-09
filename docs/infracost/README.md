# Infracost PR cost check

`Costs | infracost` (`.github/workflows/infracost.yml`) posts the monthly cost change of a
pull request as a PR comment. It estimates **only the active OpenTofu layers the PR
affects**, not the whole repository.

## What gets estimated

Scope comes from `@bin/scripts/infracost_ci`. It reuses the layer discovery of the
OpenTofu plan CI (`tofu_plan_ci.discover`), so both workflows agree on what an "affected
layer" is. Unlike the plan CI it applies no allowlist and no layer cap, because
estimating is offline HCL parsing with no AWS credentials.

| Change in the PR | Estimated |
|---|---|
| A file inside an active layer | that layer |
| `config/**` (project-wide inputs) | every active layer, like today's full run |
| `{account}/config/**` | every active layer of that account |
| A layer deleted by the PR | that layer on the base side only, so its cost shows as removed |
| A layer added by the PR | that layer on the head side only |
| A disabled layer (path segment ending in `--`) | nothing, listed as skipped |
| The check itself (workflow or `infracost_ci`) | the smoke layer `shared/us-east-1/tools-vpn-server` |
| Anything else (docs, other workflows, Python tooling) | nothing; the job skips with a `::notice::` |

The workflow's `paths:` filter is a cheap first cut; the scope step makes the real
decision. The step summary of each run lists the layers it estimated and why.

## Configuration

There is no committed `infracost.yml`. The config is generated from the layer tree: one
project per active layer, with the three var files Leverage loads for it
(`config/common.tfvars`, `{account}/config/account.tfvars`,
`{account}/config/backend.tfvars`). A new or renamed layer needs no cost-config edit.

```bash
# Every active layer, for a local breakdown (Infracost CLI v0.10, config schema 0.1)
make infracost-breakdown

# Ad hoc
PYTHONPATH=@bin/scripts python3 -m infracost_ci config --layer shared/us-east-1/tools-vpn-server
PYTHONPATH=@bin/scripts python3 -m infracost_ci --schema 0.3 scope --base origin/master --out-dir /tmp/scope
```

CI runs Infracost **CLI v2** through `infracost/actions/diff@v5` and so uses config
schema `0.3`. The local make target keeps the v0.10 `breakdown` command and schema `0.1`.

## Credentials and integrations

- **`INFRACOST_CLI_AUTHENTICATION_TOKEN`** (repo secret): a **CLI v2** token from
  dashboard.infracost.io → Organization settings → CLI tokens. A v0.1 API key, such as
  the old `INFRACOST_API_KEY`, is rejected by CLI v2 with "CI v2 needs a CLI v2 token".
- **`SLACK_WEBHOOK_URL_COST`**: when the estimate **increases**, a one-line message with the
  PR link goes to the cost channel. `diff@v5` exposes no outputs, so the headline is read
  back from the PR comment it posts.
- **Dependabot and fork PRs** get no secrets, so the job skips with a notice. A green
  check there means "did not run", not "passed".
- When a PR closes, the workflow reports its merged or closed status to the Infracost
  dashboard.

## Policies

CLI v2 applies the Infracost Cloud organization's FinOps and tagging policies, and a
policy marked **blocking** fails the job. All of them are currently **disabled** in
dashboard.infracost.io → Governance. If one is re-enabled, make it non-blocking: its findings
still show in the PR comment without turning the check red. The example "FinOps tags"
tagging policy expects `Environment` to be `Dev`/`Stage`/`Prod`, which does not match this
repository's convention (`environment` = account name).

The check is not a required status check, so a red Infracost run never blocks a merge.

<!-- infracost scope test -->
