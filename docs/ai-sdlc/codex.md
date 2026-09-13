# Working with Codex

[AGENTS.md](../../AGENTS.md) is the repository entry point for Codex. It provides
the layer model, execution boundaries, review rules, and links to task-specific
context. [The scanner instructions](../../@bin/scripts/version_support/AGENTS.md)
add its Python dependency and test requirements.

Codex discovers instructions along the path from the project root to its working
directory. Start a new session after changing instructions; when a root session
works in a subtree, have it read that subtree's guidance explicitly. Keep the root
file short and put specialized instructions next to their code. See the
[official AGENTS.md documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

Existing `CLAUDE.md` files remain useful architecture references. Codex should
follow links to them as needed; their plugin commands and tool configuration are
specific to Claude Code. This Markdown setup does not install tools, configure
MCP servers, grant AWS access, or alter sandbox permissions.

## Local setup

Use the [repository installation guide](../../README.md#getting-started). Reuse
an existing environment before installing or upgrading tools. Check locally:

```bash
# Repository root; activate the existing environment if present.
source .venv/bin/activate
leverage --version
leverage tofu --help
command -v tofu terraform pre-commit uv
```

Resolve the `leverage` executable before entering a layer, or keep the virtual
environment activated. Native `tofu` must satisfy that layer's version constraint;
the pre-commit `terraform_fmt` hook uses Terraform. Root `build.env` describes the
toolbox image used by older workflows; inspect the specific workflow and installed
CLI rather than assuming every environment runs the same version or uses Docker.

Cloud work needs operator configuration and SSO access. Use
[`config/common.tfvars.example`](../../config/common.tfvars.example) as the schema;
do not invent account IDs or replace an existing local configuration. Read the
target account's `config/account.tfvars` and `config/backend.tfvars`, then any
cross-account provider and remote-state references in the layer.

`leverage aws sso login` may require the user's browser. Check
`leverage aws sso --help` before using version-dependent refresh options. Verify
the identity for the relevant profile before cloud operations; avoid publishing
its account ID. If credentials are unavailable, finish local work and record
which live checks remain.

## Validation recipes

### Documentation or configuration-only edits

From the root, substitute the actual changed files:

```bash
git diff --check
pre-commit run --files AGENTS.md docs/ai-sdlc/codex.md --show-diff-on-failure
```

Inspect new files as well as the tracked diff, and verify relative links. Hooks
may need network access on first use and may autofix files. If dependencies are
unavailable, report that limitation and perform the applicable local checks.
Documentation-only changes need no OpenTofu init, plan, or cloud tests.

### OpenTofu layer edits

Check explicit files first; this works without AWS or backend initialization:

```bash
# Repository root; replace the example with the files actually changed.
tofu fmt -check -diff apps-devstg/us-east-1/k8s-eks-demoapps/cluster/config.tf
pre-commit run --files apps-devstg/us-east-1/k8s-eks-demoapps/cluster/config.tf --show-diff-on-failure
```

For normal configured layer work:

```bash
cd apps-devstg/us-east-1/k8s-eks-demoapps/cluster
leverage tofu format -check
leverage tofu validate
```

`format` recurses beneath the working directory, so select the smallest relevant
layer. Initialization may be needed before validation. With operator config and
the correct identity available, use `leverage tofu init`. Do not add `-upgrade`
unless the task calls for dependency changes, or migrate/reconfigure a backend
to make a validation error disappear.

For configuration validation without the remote backend, native OpenTofu can
initialize providers/modules with `tofu init -backend=false -input=false
-lockfile=readonly`, followed by `tofu validate`, from the exact layer. This still
needs dependency downloads or a usable cache, and does not verify AWS permissions
or remote-state availability. Use a disposable checkout preserving the directory
structure if isolating initialization from an already configured working copy.
If a new layer has no lock file, initialize without `-lockfile=readonly` and review
the resulting lock file as part of that layer's change.

When planning is in scope and prerequisites are available:

```bash
# Exact layer directory, with the same Leverage environment as above.
leverage tofu plan -no-color -detailed-exitcode
```

Interpret exit codes: `0` means no changes, `2` means changes are proposed, `1`
means an error. Read the plan, including destructive actions and output changes.
Do not treat a targeted plan as coverage of the full layer. Before sharing any
excerpt, inspect and redact both refresh logs and action values; trimming logs
alone does not remove sensitive data. Keep raw plans out of Git.

### Version-support and application code

Use the scanner's [scoped instructions](../../@bin/scripts/version_support/AGENTS.md)
for credential-free tests. `make version-support` performs live AWS catalog
lookups; `make version-support-table` also regenerates
[`status.md`](../version-support/status.md). Run these when relevant to version
changes, and distinguish an unavailable lookup from a clean result.

For Lambda or other application code, read that directory's README, dependency
manifest, and tests. There is no repository-wide application test command. Bedrock
invocation scripts and infrastructure tests may call real services and incur cost;
inspect them before running and use mocks for ordinary local regression coverage.

## CI and repository-specific traps

- [Static lint](../../.github/workflows/test-static-code-and-linting.yml) checks
  branch changes against `origin/master`; scheduled/manual sweeps check all files.
  Use file-scoped pre-commit locally. `make init-makefiles` replaces the ignored
  `@bin/makefiles` directory with an external checkout and is unnecessary for
  direct pre-commit or the version-support Make targets.
- [Leverage CLI integration](../../.github/workflows/leverage-cli-test.yml)
  performs init, plan, apply, and destroy. It is not a harmless lint job.
- The [version-support workflow](../../.github/workflows/version-support.yml)
  runs Python tests before its AWS phase. Forks without secrets skip the AWS
  phase; its successful job status does not prove version support was checked.
- `atlantis.yaml` remains in the tree, but the [SDLC runbook](README.md) describes
  Atlantis as deprecated and applies as maintainer operations. Do not infer an
  active deployment service or trigger it from the presence of that file.
- Backend keys are explicit and need not match the filesystem's region path.
  Preserve existing keys; moving code alone is not a state migration.
- On Apple Silicon, investigate native executable/provider architecture if an
  AWS provider hangs. Do not delete locks or change dependency versions blindly.
  If deliberately regenerating provider checksums, preserve support for CI and
  developers' platforms; inspect the existing lock and layer guidance.

## Maintaining the instructions

Keep executable code, workflow files, and dependency manifests authoritative for
current behavior. Update guidance alongside a workflow change. Prefer links to
existing layer docs over duplicating their architecture. Add a nested `AGENTS.md`
only when a subtree has distinct commands, invariants, or risks; do not create one
per account merely to repeat the root rules.

To check discovery, start a fresh Codex session at the root or in the scanner
directory and ask it to list its active instruction files. Root sessions should
identify `AGENTS.md`; scanner sessions should also identify the scoped file.
