# Codex repository instructions

## Start here

This is the Binbash Leverage AWS reference architecture: independent OpenTofu
root modules (called **layers**) across multiple AWS accounts. It is not one
Terraform project that can be initialized or planned from the repository root.

- Read `git status --short` before editing; preserve unrelated changes, including
  existing `.terraform.lock.hcl` edits. Keep changes scoped to the requested task.
- Identify the account, region, and exact layer(s). Read their `README.md`, any
  deployment notes, and applicable nested `AGENTS.md` before changing code. When
  starting at the repository root, explicitly check the target subtree for guidance.
- Read a layer's `CLAUDE.md` when present for additional architecture context;
  verify commands against code and installed CLI help. Claude plugins, slash
  commands, and `.mcp.json` settings do not establish Codex tool availability.
- Use [the Codex runbook](docs/ai-sdlc/codex.md) for setup, validation commands,
  and troubleshooting. Read only the references relevant to the task.
- Complete local edits and appropriate checks autonomously. Ask only for missing
  information or authorization that materially blocks the next action; retain
  authorization already given in the conversation.

## Repository map

| Path | Responsibility |
| --- | --- |
| `management/` | Organizations, SSO, billing, account governance |
| `security/` | Central security, audit, compliance |
| `network/` | VPCs, transit gateways, routing, VPN, firewall |
| `shared/` | Shared services, DNS, registries, operational tools |
| `apps-devstg/`, `apps-prd/` | Development/staging and production workloads |
| `data-science/` | Bedrock, document processing, analytics, data platforms |
| `config/`, `*/config/` | Common variables and account/backend configuration |
| `@bin/scripts/version_support/` | Python lifecycle scanner; read its `AGENTS.md` |
| `.github/workflows/` | Actual CI behavior and automation permissions |

Layers usually live at `{account}/{global|region}/{layer}`; some have additional
levels, such as `k8s-eks-demoapps/cluster`. A directory segment ending in `--`
marks disabled/optional infrastructure, with or without a preceding space.
Preserve that suffix and quote paths containing spaces. Do not activate a layer
as incidental cleanup; inspect automation configuration before assuming it is excluded.

## Infrastructure conventions

- Prefer existing versioned Binbash modules and nearby working patterns. Inspect
  the layer's `required_version`, `required_providers`, module refs, and lock file;
  versions vary across the repository. Avoid unrelated upgrades or new abstractions.
- `config.tf` typically contains providers, the S3 backend key, and
  `terraform_remote_state` dependencies. Trace both producers and consumers before
  changing outputs, resource addresses, provider aliases, or state keys. Search
  `locals.tf` too: some remote states are generated from maps with `for_each`.
- Preserve `common-variables.tf` symlinks. Inspect their targets before editing:
  changing the shared `config/common-variables.tf` affects many layers. Compute
  relative links from the actual layer depth when creating a layer.
- Leverage loads root `config/common.tfvars`, account `config/account.tfvars`,
  and account `config/backend.tfvars`. Inspect layer `.auto.tfvars` overrides too.
  `config/common.tfvars` and `*.local.auto.tfvars` are operator-local, ignored files;
  update the corresponding examples for new configuration requirements.
- Keep naming and tags consistent with the layer (`var.project`, `var.environment`,
  `local.tags`). `local.layer_name` and `local.current_region` depend on `path.cwd`:
  moving a layer can change resource names as well as execution context.
- Read the actual backend and cross-account profiles; do not assume every profile
  ends in `-devops`. Production uses `bb-apps-prd-devopsprd`. SSO permission-set
  renames require checking account config, all profile references, and workflows.
- Preserve encryption, least-privilege access, backup/deletion protection, and
  existing ownership of resources across layers. Explain intentional changes to them.

## Execution and validation

- Prefer `leverage tofu` (`leverage tf` is an alias) for supported operations,
  from the exact layer directory. The formatting command is `format`, not `fmt`.
  Resolve the executable before changing directories; `.venv/bin/leverage` is
  relative to the repository root. Check `leverage tofu --help` for actual support.
- Start with checks that need no AWS credentials. Use `tofu fmt -check -diff`
  on explicit changed files, then `pre-commit run --files ...` from the root.
  Hooks can modify files: inspect their diff. Do not format all accounts for a
  layer-sized change. Full command examples and init options are in the runbook.
- Validate changed layers when providers/modules are available. A successful
  format check is not validation; validation is not a live plan. Report each
  separately, including missing credentials, dependencies, or network access.
- Plans require the correct AWS identity, backend, variables, and remote states.
  Check these first; avoid `-target` and `-lock=false` as routine workarounds.
  Review replacements, deletes, IAM changes, and downstream effects explicitly.
- Infrastructure apply is normally a maintainer step after plan review, per
  `docs/ai-sdlc/README.md`. A request to edit/review code does not authorize apply,
  destroy, import, state mutation, force-unlock, or deployment scripts. If the user
  explicitly authorizes an operation, honor that scope and verify its target and
  prerequisites without asking for the same authorization again.
- Inspect tests before executing them. `tofu test` and the Leverage CLI CI workflow
  can create and destroy real infrastructure; the KMS tests are not fully mocked.
  Do not run them as an offline check. Never dispatch cloud workflows just to lint.

## Review and delivery

- Follow [CONTRIBUTING.md](CONTRIBUTING.md) and the PR template's What / Why /
  References structure. Update relevant layer docs for changed inputs or behavior.
- Do not commit credentials, decrypted vault files, state, saved plans, test
  documents, or local runtime/cache files. Do not print credential files or secret
  values. Redact AWS account IDs, account-bearing ARNs, and credential identifiers
  from shared plan excerpts and PR text. Plan action sections can contain secrets.
- Keep `k8s-components/crds/` vendored upstream bundles byte-identical unless
  deliberately upgrading them; the whitespace hook excludes these files.
- Describe what changed, affected layers and dependencies, checks actually run,
  and any outstanding live validation. Do not claim skipped checks passed.
- When committing is requested, use technical commit messages without AI
  attribution. Posting comments or messages requires the user's authorization.

## Code Review Rules

- Flag changes that can replace/destroy resources, break remote-state consumers,
  misroute cross-account access, or activate disabled infrastructure without an
  explicit migration/deployment explanation.
- Flag broadened IAM/trust policies, public exposure, secret disclosure, or removal
  of encryption/backup safeguards when not required and explained by the change.
- For EKS/RDS upgrades, check layer-specific sequencing and the version-support
  guardrail. An unavailable AWS lookup or skipped fork check is not evidence of
  supported versions. Leave formatting enforcement to the existing hooks.
