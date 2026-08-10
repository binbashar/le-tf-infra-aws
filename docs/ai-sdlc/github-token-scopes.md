# GitHub token scopes for AI agent workflows

Which GitHub token an AI agent needs to drive the workflows in this repo, what each
scope unlocks, and how to tell the three different causes of GitHub's ambiguous
`403 Resource not accessible by personal access token` apart.

Scope tables below were verified against this repo on **2026-07-25**.

> See also: [`README.md`](README.md) for the end-to-end SDLC flow, and
> [`claude-code-bedrock.md`](claude-code-bedrock.md) for routing local Claude Code
> sessions through Bedrock.

---

## 1. Which token do you need?

Two different paths, and they fail in different ways. Pick the row that matches what
you are wiring up.

| Use case | Token | Why |
| --- | --- | --- |
| **Local Claude Code + GitHub MCP server** | `gh` CLI OAuth token (`gho_…`) | Inherits your own OAuth scopes, so there is no fine-grained scope matrix to get wrong. See [§5](#5-local-claude-code-the-gh-cli-shortcut). |
| **CI / unattended automation** (agent-driven PRs, `release-management`) | Fine-grained PAT | No interactive login available. Scopes must be granted explicitly — see [§2](#2-fine-grained-pat-required-scopes). |

## 2. Fine-grained PAT: required scopes

Split by what each one actually unlocks, so you can grant the minimum for the
workflow you need rather than copying the whole set:

| Scope | Enables |
| --- | --- |
| `Metadata: RO` | Mandatory baseline — GitHub requires it alongside any other scope. |
| `Contents: RO` | Read files, list branches. |
| `Contents: RW` | Create branches, commit files — **required for any PR-opening workflow**. |
| `Issues: RW` | Create / comment / label / close issues. |
| `Pull requests: RW` | Open, update, merge PRs. |

**The `Contents` level is the one that catches people.** With `Contents: RO` an agent
can read code, triage, and discuss, but `POST /git/refs` fails — so it can never push
the branch a PR would be built from. Triage-only agents are fine at `RO`; anything
that opens a PR needs `RW`.

Verified behaviour at `Issues: RW`, `Pull requests: RW`, `Contents: RO`, `Metadata: RO`:

| Operation | Result |
| --- | --- |
| Read files, list branches / issues / PRs | ✅ works |
| Create an issue | ✅ works |
| Comment on an issue or PR | ✅ works |
| `POST /git/refs` (create a branch) | ❌ `403 Resource not accessible by personal access token` |

## 3. Resource owner must be `binbashar`

A fine-grained PAT is scoped to a **resource owner**. A token owned by your personal
account cannot write to an org repo *no matter which scopes you tick* — the scopes
apply to resources the owner controls.

- Set the resource owner to **`binbashar`** when creating the token, not your personal account.
- Org owners then approve it at
  `https://github.com/organizations/binbashar/settings/personal-access-tokens-pending`.
- Until it is approved, the token behaves like it has no permissions at all.

## 4. Troubleshooting the ambiguous 403

`403 Resource not accessible by personal access token` is returned for at least three
distinct causes, and the fixes have nothing in common:

| 403 on | Cause | Fix |
| --- | --- | --- |
| *Every* write, including issue comments | PAT resource owner is a personal account | Regenerate with owner `binbashar` ([§3](#3-resource-owner-must-be-binbashar)) |
| Branch creation / commits only | `Contents` is `RO` | Raise `Contents` to `RW` ([§2](#2-fine-grained-pat-required-scopes)) |
| `GET /orgs/{org}/issue-types` | Org-level endpoint, org permission absent | Grant org read, or omit `type` on issue creation |

### The cheap discriminator

**If an issue comment succeeds but branch creation fails with the same 403, it is a
scope problem, not a resource-owner problem.**

Worth stating explicitly because without that check the natural move is to regenerate
the token — which returns the identical error, costs an org-approval round trip, and
teaches you nothing.

```bash
# Succeeds but branch creation 403s  ->  raise Contents to RW.
# Also 403s                          ->  fix the resource owner first.
gh api "repos/binbashar/le-tf-infra-aws/issues/<N>/comments" -f body="scope probe"
```

## 5. Local Claude Code: the `gh` CLI shortcut

For local sessions the GitHub MCP server authenticates with
`Authorization: Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}`. Rather than minting a
fine-grained PAT, export the `gh` CLI's own OAuth token — it carries the scopes you
already have, so §2's matrix does not apply:

```bash
# ~/.zshrc  (or ~/.bashrc)
export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"
```

Two gotchas, both verified on 2026-07-25:

- **When the variable is unset the header ships empty**, and GitHub returns
  `HTTP 400: Authorization header is badly formatted`. That surfaces in the client as a
  *connection* failure rather than an auth one, which sends you debugging the wrong layer.
- **A client restart is required** — the MCP server reads the variable from the
  environment at spawn time. `claude mcp list` reporting *Connected* only means the
  process started; it does not prove the token works. Confirm with one real read call.

## 6. Compensating controls

`Contents: RW` sounds broad, but it does **not** grant a direct push to the default
branch here:

- **`master` is protected**, so changes still have to arrive as a PR for human review.
  This keeps the standing rule — plans go to a PR, a human runs `apply` — enforced at
  the platform level rather than depending on agent behaviour.
- **Scope the token to an explicit repository list** rather than all of `binbashar`.
- **Confirm equivalent branch protection** on any repo you later add to that list —
  otherwise `Contents: RW` there really does mean unreviewed pushes.

## Related references

- SDLC flow and CI checks: [`README.md`](README.md)
- Project conventions and commands: [`CLAUDE.md`](../../CLAUDE.md)
- GitHub docs: [Fine-grained PAT permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens)
