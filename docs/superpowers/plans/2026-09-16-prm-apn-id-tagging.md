# PRM `aws-apn-id` Tagging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put the PRM cost allocation tag `aws-apn-id = pc:<marketplace-product-code>` on every one of the 163 OpenTofu layers in this repo, sourced from a single account-keyed map, and add a guardrail so new layers cannot silently omit it.

**Architecture:** One `locals` addition in `config/common-variables.tf` (symlinked into every layer) defines the account→product-code map and resolves `local.prm_apn_id` from `var.environment`. Each layer then references that local from its existing `local.tags`. A stdlib-only Python checker enforces presence across the tree, wired into `make` and pre-commit. Tag activation for cost allocation lives in `management/global/cost-mgmt`.

**Tech Stack:** OpenTofu (`leverage tofu` wrapper), HCL, Python 3 (stdlib only), pytest, pre-commit, GNU make.

**Spec:** `docs/superpowers/specs/2026-09-16-prm-apn-id-tagging-design.md`

**Branch:** `feat/prm-apn-id-tagging` (already created off `origin/master`)

---

## Reference values (do not retype from memory)

| Key | Value |
|---|---|
| Tag key | `aws-apn-id` |
| Horizontal code (all accounts except `data-science`) | `pc:5k5o9j3cjaqzpbiwt7ww6e65o` |
| Horizontal listing | *Leverage \| AWS Modernization (Containers / Serverless)*, `prod-pkadanxklqjdc`, Public |
| AI code (`data-science` only) | `pc:b6t445987ttlzwgcll8zdt8nv` |
| AI listing | *GenAI Assessment for Startups \| AI/ML Readiness & Roadmap*, `prod-zw4ehbg5ayh2m`, Public |

Layer inventory as of 2026-09-16: **163 total** — 98 active, 65 disabled; **127** have a `locals` `tags` map the insertion script can extend, **36** do not.

---

### Task 1: Guardrail checker (write it first — it is the test for Tasks 3 and 4)

**Files:**
- Create: `@bin/scripts/prm_tags/check.py`
- Create: `@bin/scripts/prm_tags/allowlist.txt`
- Create: `@bin/scripts/prm_tags/tests/test_check.py`

Written before the tagging so its first run enumerates exactly the work to do, and its exit code proves when that work is complete.

- [ ] **Step 1: Write the failing test**

Create `@bin/scripts/prm_tags/tests/test_check.py`:

```python
"""Tests for the PRM aws-apn-id tag guardrail."""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import check  # noqa: E402


def _layer(tmp_path, rel, tf_files):
    """Create a layer directory with the given {filename: contents} files."""
    directory = tmp_path / rel
    directory.mkdir(parents=True)
    for name, body in tf_files.items():
        (directory / name).write_text(body, encoding="utf-8")
    return directory


TAGGED = 'locals {\n  tags = {\n    "aws-apn-id" = local.prm_apn_id\n  }\n}\n'
UNTAGGED = 'locals {\n  tags = {\n    Terraform = "true"\n  }\n}\n'


def test_layer_dirs_finds_only_dirs_with_config_tf(tmp_path):
    _layer(tmp_path, "shared/us-east-1/base-network", {"config.tf": "", "locals.tf": TAGGED})
    _layer(tmp_path, "shared/us-east-1/notalayer", {"locals.tf": TAGGED})
    assert sorted(check.layer_dirs(str(tmp_path))) == ["shared/us-east-1/base-network"]


def test_layer_dirs_skips_vendor_and_state_dirs(tmp_path):
    _layer(tmp_path, ".terraform/modules/x", {"config.tf": ""})
    _layer(tmp_path, "shared/us-east-1/base-network", {"config.tf": "", "locals.tf": TAGGED})
    assert sorted(check.layer_dirs(str(tmp_path))) == ["shared/us-east-1/base-network"]


def test_tagged_layer_passes(tmp_path):
    directory = _layer(tmp_path, "shared/us-east-1/a", {"config.tf": "", "locals.tf": TAGGED})
    assert check.has_prm_tag(str(directory)) is True


def test_untagged_layer_is_reported(tmp_path):
    directory = _layer(tmp_path, "shared/us-east-1/a", {"config.tf": "", "locals.tf": UNTAGGED})
    assert check.has_prm_tag(str(directory)) is False


def test_tag_found_when_it_lives_in_main_tf(tmp_path):
    # Two layers in this repo keep their tags map in main.tf, not locals.tf.
    directory = _layer(tmp_path, "a/b/c", {"config.tf": "", "main.tf": TAGGED})
    assert check.has_prm_tag(str(directory)) is True


def test_disabled_layers_are_checked_too(tmp_path):
    # All three disabled-suffix forms occur in this repo and every layer is
    # tagged, so none of them is exempt.
    for rel in ("a/us-east-1/x --", "a/us-east-1/y--", "a/us-east-1/z -- "):
        _layer(tmp_path, rel, {"config.tf": "", "locals.tf": UNTAGGED})
    assert check.main(["--root", str(tmp_path), "--allowlist", str(tmp_path / "none.txt")]) == 1


def test_allowlisted_layer_is_not_reported(tmp_path):
    _layer(tmp_path, "management/global/organizations", {"config.tf": "", "locals.tf": UNTAGGED})
    allowlist = tmp_path / "allow.txt"
    allowlist.write_text(
        "# creates only Organizations resources, none taggable\n"
        "management/global/organizations\n",
        encoding="utf-8",
    )
    assert check.main(["--root", str(tmp_path), "--allowlist", str(allowlist)]) == 0


def test_load_allowlist_strips_comments_and_blanks(tmp_path):
    allowlist = tmp_path / "allow.txt"
    allowlist.write_text("\n# a comment\n a/b/c  # trailing reason\n\n", encoding="utf-8")
    assert check.load_allowlist(str(allowlist)) == {"a/b/c"}


def test_clean_tree_exits_zero(tmp_path):
    _layer(tmp_path, "shared/us-east-1/a", {"config.tf": "", "locals.tf": TAGGED})
    assert check.main(["--root", str(tmp_path), "--allowlist", str(tmp_path / "none.txt")]) == 0
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
pytest ./@bin/scripts/prm_tags/tests/ -q
```

Expected: collection error — `ModuleNotFoundError: No module named 'check'`.

- [ ] **Step 3: Write the checker**

Create `@bin/scripts/prm_tags/check.py`:

```python
#!/usr/bin/env python3
"""Assert every OpenTofu layer carries the PRM `aws-apn-id` tag.

PRM (AWS Partner Revenue Measurement) attributes AWS consumption to an AWS
Marketplace listing through the cost allocation tag `aws-apn-id`. A layer that
omits it drives spend that is never attributed to binbash -- invisible at plan
time and at apply time, which is exactly why it needs a static check.

Every layer is checked, disabled ones included: they are tagged too, so that
enabling a layer never silently starts unattributed spend. Layers that create
nothing taggable (Organizations, Identity Center, IAM-only) are listed in
allowlist.txt with a reason.

Stdlib only, no AWS credentials, no network. Run from the repository root:

    python3 @bin/scripts/prm_tags/check.py --root .
"""

from __future__ import annotations

import argparse
import os
import sys

TAG_KEY = "aws-apn-id"

# Vendored provider caches, virtualenvs and worktrees hold .tf files that are
# not layers of this repo; @bin holds the version_support test fixtures, which
# are deliberately shaped like layers.
SKIP_DIRS = {
    ".git",
    ".terraform",
    ".venv",
    ".worktrees",
    ".infracost",
    "@bin",
    "node_modules",
    "__pycache__",
}


def layer_dirs(root: str):
    """Yield every layer path relative to root. A layer is a dir with config.tf."""
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        if "config.tf" not in filenames:
            continue
        rel = os.path.relpath(dirpath, root).replace(os.sep, "/")
        if rel == "." or rel.startswith("."):
            continue
        yield rel


def has_prm_tag(layer_path: str) -> bool:
    """True when any .tf file in the layer references the tag key.

    Deliberately a substring check rather than an HCL parse: this catches the
    forgotten-line case, which is the only one that happens in practice, while
    staying dependency-free. Whether the tag actually reaches resources is
    settled by `leverage tofu plan`, not by this check.
    """
    for name in sorted(os.listdir(layer_path)):
        if not name.endswith(".tf"):
            continue
        full = os.path.join(layer_path, name)
        if not os.path.isfile(full):
            continue
        with open(full, encoding="utf-8", errors="ignore") as handle:
            if TAG_KEY in handle.read():
                return True
    return False


def load_allowlist(path: str) -> set[str]:
    """Read allowlist.txt: one layer path per line, `#` starts a comment."""
    if not os.path.exists(path):
        return set()
    entries = set()
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            entry = line.split("#", 1)[0].strip()
            if entry:
                entries.add(entry)
    return entries


def main(argv: list[str] | None = None) -> int:
    default_allowlist = os.path.join(os.path.dirname(os.path.abspath(__file__)), "allowlist.txt")
    parser = argparse.ArgumentParser(description="Check the PRM aws-apn-id tag on every layer.")
    parser.add_argument("--root", default=".", help="repository root (default: .)")
    parser.add_argument("--allowlist", default=default_allowlist, help="path to allowlist.txt")
    args = parser.parse_args(argv)

    allowed = load_allowlist(args.allowlist)
    missing = [
        rel
        for rel in sorted(layer_dirs(args.root))
        if rel not in allowed and not has_prm_tag(os.path.join(args.root, rel))
    ]

    if missing:
        print(f"{len(missing)} layer(s) missing the PRM '{TAG_KEY}' tag:\n")
        for rel in missing:
            print(f"  {rel}")
        print(f'\nAdd `"{TAG_KEY}" = local.prm_apn_id` to the layer\'s local.tags map,')
        print("or add the layer to @bin/scripts/prm_tags/allowlist.txt with a reason.")
        return 1

    print(f"OK - every layer carries the PRM '{TAG_KEY}' tag.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

Create `@bin/scripts/prm_tags/allowlist.txt`:

```text
# Layers exempt from the PRM `aws-apn-id` tag check.
#
# A layer belongs here only when it creates nothing taggable -- IAM,
# Organizations and Identity Center resources take no tags, and none of those
# services is in the PRM Resource Tagging Included Services list anyway.
#
# One layer path per line, relative to the repository root, each with a reason.
# Populated in Task 4; keep it empty until then.
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
pytest ./@bin/scripts/prm_tags/tests/ -q
```

Expected: `9 passed`.

- [ ] **Step 5: Run the checker against the real tree to capture the starting state**

```bash
python3 @bin/scripts/prm_tags/check.py --root . | tail -5
python3 @bin/scripts/prm_tags/check.py --root . | head -1
```

Expected: exit 1, first line `160 layer(s) missing the PRM 'aws-apn-id' tag:` — 163 layers minus the 3 `data-science` Bedrock layers already tagged by #1071.

If the count is not 160, stop: the inventory in the spec has drifted and the plan needs re-basing before any layer is touched.

- [ ] **Step 6: Commit**

```bash
git add '@bin/scripts/prm_tags'
git commit -m "feat(prm): add the aws-apn-id tag guardrail

Stdlib-only checker asserting every layer carries the PRM cost allocation
tag, with an allowlist for layers that create nothing taggable. Added
before the tagging itself so its output enumerates the work and its exit
code proves when the work is done."
```

---

### Task 2: Central product-code map

**Files:**
- Modify: `config/common-variables.tf` (the `locals` block at the end of the file)

- [ ] **Step 1: Read the current locals block**

```bash
sed -n '/^locals {/,$p' config/common-variables.tf
```

Expected: a block defining `regions`, `current_region` and `layer_name`.

- [ ] **Step 2: Add the product-code map**

Insert into that existing `locals` block, after the `layer_name` line and before the closing brace:

```hcl

  #===========================================#
  # PRM -- AWS Partner Revenue Measurement    #
  #===========================================#
  # `aws-apn-id = pc:<marketplace-product-code>` attributes AWS consumption to
  # an AWS Marketplace listing. Keyed by account: var.environment equals the
  # account directory name in every {account}/config/account.tfvars.
  #
  # Only Public, Active listings belong here -- a Restricted listing is
  # de-listed and does not satisfy the "at least one public listing"
  # requirement. Retrieve a code with:
  #
  #   aws marketplace-catalog describe-entity --catalog AWSMarketplace \
  #     --entity-id prod-xxxxxxxxxxxxx \
  #     --query 'DetailsDocument.Description.ProductCode' --output text
  prm_product_codes = {
    default        = "pc:5k5o9j3cjaqzpbiwt7ww6e65o" # Leverage | AWS Modernization (Containers / Serverless) -- prod-pkadanxklqjdc
    "data-science" = "pc:b6t445987ttlzwgcll8zdt8nv" # GenAI Assessment for Startups | AI/ML Readiness & Roadmap -- prod-zw4ehbg5ayh2m
  }

  prm_apn_id = lookup(local.prm_product_codes, var.environment, local.prm_product_codes["default"])
```

- [ ] **Step 3: Format and verify the file still parses**

```bash
.venv/bin/leverage tofu format
git diff --stat config/common-variables.tf
```

Expected: `config/common-variables.tf` shows insertions only, no deletions beyond whitespace realignment.

- [ ] **Step 4: Verify the value resolves per account**

The local is unused until Task 3, so evaluate it directly in an already-initialised layer:

```bash
cd management/global/cost-mgmt && echo 'local.prm_apn_id' | tofu console ; cd - >/dev/null
```

Expected: `"pc:5k5o9j3cjaqzpbiwt7ww6e65o"` (management resolves to the default).

```bash
cd data-science/us-east-1/bedrock-agentcore && echo 'local.prm_apn_id' | tofu console ; cd - >/dev/null
```

Expected: `"pc:b6t445987ttlzwgcll8zdt8nv"` (data-science resolves to the AI code).

If `tofu console` reports the layer is not initialised, run `.venv/bin/leverage tofu init` in that layer first. If credentials have expired, run `.venv/bin/leverage aws sso login` followed by `.venv/bin/leverage aws sso refresh`.

**This step is the one that proves the whole design works. Do not skip it.** If `data-science` returns the default code, `var.environment` is not what the spec assumes and Tasks 3–4 would tag 21 layers with the wrong product.

- [ ] **Step 5: Commit**

```bash
git add config/common-variables.tf
git commit -m "feat(prm): add the account-keyed aws-apn-id product code map

Defines local.prm_apn_id once, in the file symlinked into every layer, so
a product code change is a one-line edit instead of 163. Keyed on
var.environment, which already equals the account directory name in all
seven {account}/config/account.tfvars."
```

---

### Task 3: Wire the tag into the 127 layers that have a tags map

**Files:**
- Modify: 127 layer files (mostly `locals.tf`; two layers keep the map in `main.tf`)
- Create (temporary, deleted in Step 5): `/tmp/prm-insert.py`

- [ ] **Step 1: Write the insertion script**

Create `/tmp/prm-insert.py`:

```python
#!/usr/bin/env python3
"""One-shot: insert the PRM tag line into every layer's locals tags map.

Brace-matches the `tags = {` map inside a `locals {` block and inserts the tag
as its last entry. Layers already mentioning the key are rewritten only when
they carry the literal product code (the three #1071 Bedrock layers), so they
end up sourcing the shared local like everything else.
"""

import os
import re
import sys

TAG_LINE = '    "aws-apn-id" = local.prm_apn_id\n'
LITERAL = re.compile(r'^(\s*)"aws-apn-id"\s*=\s*"pc:[a-z0-9]+"\s*$', re.M)
SKIP_DIRS = {".git", ".terraform", ".venv", ".worktrees", ".infracost",
             "@bin", "node_modules", "__pycache__"}


def close_index(text, open_after):
    """Index of the `}` closing the block whose `{` ended at open_after."""
    depth, i = 1, open_after
    while i < len(text) and depth:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    return i - 1


def rewrite(text):
    """Return updated text, or None when there is nothing to change."""
    if '"aws-apn-id"' in text:
        # Already tagged: collapse a hardcoded pc: literal onto the shared local.
        new = LITERAL.sub(r'\1"aws-apn-id" = local.prm_apn_id', text)
        return new if new != text else None

    for match in re.finditer(r"(?m)^locals\s*\{", text):
        block_end = close_index(text, match.end())
        tags = re.search(r"(?m)^[ \t]{2,}tags\s*=\s*\{", text[match.end():block_end])
        if not tags:
            continue
        close = close_index(text, match.end() + tags.end())
        line_start = text.rfind("\n", 0, close) + 1
        return text[:line_start] + TAG_LINE + text[line_start:]
    return None


def main(root):
    changed = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        if "config.tf" not in filenames:
            continue
        rel = os.path.relpath(dirpath, root)
        if rel.startswith("."):
            continue
        for name in sorted(filenames):
            if not name.endswith(".tf"):
                continue
            path = os.path.join(dirpath, name)
            with open(path, encoding="utf-8") as handle:
                text = handle.read()
            new = rewrite(text)
            if new is not None:
                with open(path, "w", encoding="utf-8") as handle:
                    handle.write(new)
                changed.append(os.path.relpath(path, root))
                break  # one tags map per layer
    for path in changed:
        print(path)
    print(f"\n{len(changed)} file(s) changed", file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
```

- [ ] **Step 2: Run it**

```bash
python3 /tmp/prm-insert.py . > /tmp/prm-changed.txt
wc -l < /tmp/prm-changed.txt
```

Expected: `127`.

- [ ] **Step 3: Verify every change is exactly one added line**

This is the safety check that the brace matcher did not damage a file:

```bash
git diff --numstat | awk '$1 != 1 || $2 != 0 {print "SUSPECT:", $0}'
```

Expected: no output. Any file showing a deletion, or more than one insertion, means the matcher mis-fired on that file — inspect it with `git diff -- <path>` before continuing.

The three #1071 Bedrock layers are the exception and will show `1 1` (literal replaced by the local). Confirm they are exactly these three and no others:

```bash
git diff --numstat | awk '$1 == 1 && $2 == 1 {print $3}'
```

Expected exactly:
```text
data-science/us-east-1/bedrock-agent-kyb/locals.tf
data-science/us-east-1/bedrock-agentcore/locals.tf
data-science/us-east-1/bedrock-kyb-bda/locals.tf
```

- [ ] **Step 4: Format and confirm the tree still parses**

```bash
.venv/bin/leverage tofu format
```

Expected: exits 0. It rewrites alignment inside the tags maps; that is the only additional change.

- [ ] **Step 5: Re-run the guardrail**

```bash
rm /tmp/prm-insert.py /tmp/prm-changed.txt
python3 @bin/scripts/prm_tags/check.py --root . | head -1
```

Expected: `36 layer(s) missing the PRM 'aws-apn-id' tag:` — the layers with no tags map, handled in Task 4.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(prm): source aws-apn-id from the shared local in 127 layers

Adds \`\"aws-apn-id\" = local.prm_apn_id\` to every layer that already keeps
a locals tags map, and converts the three Bedrock layers from #1071 off
their hardcoded product code onto the same local. Those three resolve to
the identical value, so their plans stay empty.

The 36 layers with no tags map are handled separately."
```

---

### Task 4: The 36 layers with no tags map

**Files:**
- Modify: up to 36 layer `locals.tf` / `main.tf` files
- Modify: `@bin/scripts/prm_tags/allowlist.txt`

These need judgment, not a script: adding a `local.tags` that nothing consumes is theatre. Work through them one at a time.

- [ ] **Step 1: List them**

```bash
python3 @bin/scripts/prm_tags/check.py --root . | sed -n '3,$p' | sed '/^$/,$d'
```

The 16 **active** ones are:

```text
apps-devstg/us-east-1/k8s-eks-demoapps/k8s-components
apps-devstg/us-east-1/k8s-eks-demoapps/k8s-workloads
apps-devstg/us-east-1/security-base
apps-devstg/us-east-1/tools-cloud-nuke
apps-prd/us-east-1/security-base
data-science/us-east-1/security-base
management/global/organizations
management/us-east-1/security-base
management/us-east-1/security-compliance
network/us-east-1/client-vpn
network/us-east-1/security-base
security/us-east-2/security-audit
shared/us-east-1/k8s-eks-demoapps/identities
shared/us-east-1/security-base
shared/us-east-1/tools-cloud-scheduler-stop-start
shared/us-east-2/container-registry
```

The remaining 20 are disabled (`--`) layers: `apps-devstg/us-east-1/datalake--`, the `k8s-kind --`
and `k8s-kops --` trees, `security/us-east-1/tools-wazuh --`, and the `security-compliance --`,
`security-hub --` and `security-monitoring --` layers across every account.

- [ ] **Step 2: For each layer, decide wire-or-allowlist**

For one layer at a time:

```bash
LAYER=shared/us-east-1/secrets-manager
grep -rnE '^\s*(resource|module)\s+"' $LAYER/*.tf | head -20
grep -rn 'tags' $LAYER/*.tf | head -20
```

Decide using this rule:

- **Any resource or module that accepts `tags`** → wire it. Add a `locals.tf` (or extend the existing `locals` block) with the standard map, and pass `tags = local.tags` to each resource/module that takes it:

  ```hcl
  locals {
    tags = {
      Terraform    = "true"
      Environment  = var.environment
      Layer        = local.layer_name
      "aws-apn-id" = local.prm_apn_id
    }
  }
  ```

- **Nothing taggable** — the layer creates only IAM, Organizations, Identity Center, or Kubernetes/Helm objects with no AWS resources — → allowlist it. Append to `@bin/scripts/prm_tags/allowlist.txt` with the reason on the same line:

  ```text
  management/global/organizations  # aws_organizations_* and IAM only; neither is taggable nor in the PRM service list
  ```

Expected allowlist candidates, to be confirmed rather than assumed: `management/global/organizations`, `shared/us-east-1/k8s-eks-demoapps/identities`, and the `k8s-components` / `k8s-workloads` / `k8s-kind --` / `k8s-kops --` layers (Kubernetes and Helm providers, not AWS).

Expected wiring candidates: `shared/us-east-2/container-registry` (ECR), `network/us-east-1/client-vpn` (VPC), `apps-devstg/us-east-1/tools-cloud-nuke` (Lambda), `shared/us-east-1/tools-cloud-scheduler-stop-start` (Lambda/EventBridge), the `security-base` layers (KMS, SNS) and `apps-devstg/us-east-1/datalake--` (S3/Glue).

Note `management/global/sso` and `shared/us-east-1/secrets-manager` are **not** in this set: both do
have a tags map, further into their `locals` block than a naive scan reaches, and Task 3 handles them.

- [ ] **Step 3: Re-run the guardrail after each batch**

```bash
python3 @bin/scripts/prm_tags/check.py --root . | head -1
```

Expected once every layer is resolved: `OK - every layer carries the PRM 'aws-apn-id' tag.` and exit 0.

- [ ] **Step 4: Format**

```bash
.venv/bin/leverage tofu format
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(prm): tag or allowlist the 36 layers with no tags map

Layers that create taggable AWS resources get a standard local.tags map
wired into their resources and modules. Layers that create only IAM,
Organizations, Identity Center or Kubernetes objects are allowlisted with
the reason recorded inline -- none of those services is taggable, and none
appears in the PRM Resource Tagging Included Services list."
```

---

### Task 5: Activate the tag for cost allocation

**Files:**
- Modify: `management/global/cost-mgmt/cost_anomaly.tf` — or create `management/global/cost-mgmt/cost_allocation_tags.tf`

Without activation the tag reaches resources but never reaches Cost Explorer or the CUR, so attribution cannot be verified.

- [ ] **Step 1: Confirm the resource exists in the pinned provider**

```bash
grep -n -A4 'aws = {' management/global/cost-mgmt/config.tf
```

Expected: `version = "5.100.0"`. `aws_ce_cost_allocation_tag` is present in that release; if the pin has moved below 5.x, stop and raise it first.

- [ ] **Step 2: Add the resource**

Create `management/global/cost-mgmt/cost_allocation_tags.tf`:

```hcl
#
# Activating a user-defined tag as a cost allocation tag is what makes it
# visible in Cost Explorer and the CUR. Applying the tag to resources is not
# enough on its own -- an inactive tag leaves the spend reading as untagged,
# which is exactly how PRM attribution silently fails to be verifiable.
#
# Payer-account only: cost allocation tags are an organization-wide setting
# owned by the management account.
#
resource "aws_ce_cost_allocation_tag" "prm_apn_id" {
  tag_key = "aws-apn-id"
  status  = "Active"
}
```

- [ ] **Step 3: Format and plan**

```bash
cd management/global/cost-mgmt
../../../.venv/bin/leverage tofu init
../../../.venv/bin/leverage tofu plan -no-color 2>&1 | tail -30
cd - >/dev/null
```

Expected: one resource to add (`aws_ce_cost_allocation_tag.prm_apn_id`) plus in-place tag updates on the existing anomaly monitor. **No replacements.**

- [ ] **Step 4: Commit**

```bash
git add management/global/cost-mgmt/cost_allocation_tags.tf
git commit -m "feat(prm): activate aws-apn-id as a cost allocation tag

An applied-but-inactive tag never reaches Cost Explorer or the CUR, so
attribution cannot be verified and the spend keeps reading as untagged.
Payer-account setting, hence management/global/cost-mgmt."
```

---

### Task 6: Wire the guardrail into make and pre-commit

**Files:**
- Modify: `Makefile`
- Modify: `.pre-commit-config.yaml`

- [ ] **Step 1: Add the make target**

Append to `Makefile`, after the `version-support-table` target:

```make
# Stdlib only -- no uv, no requirements file, no AWS. Deliberately unlike
# version-support, which needs python-hcl2 and live AWS lifecycle data.
.PHONY: prm-tags
prm-tags: ## Check every layer carries the PRM aws-apn-id tag
	@python3 @bin/scripts/prm_tags/check.py --root .

.PHONY: prm-tags-test
prm-tags-test: ## Run the PRM tag guardrail's own tests
	@pytest ./@bin/scripts/prm_tags/tests/ -q
```

- [ ] **Step 2: Verify the target**

```bash
make prm-tags
```

Expected: `OK - every layer carries the PRM 'aws-apn-id' tag.`, exit 0.

```bash
make prm-tags-test
```

Expected: `9 passed`.

- [ ] **Step 3: Add the pre-commit hook**

Append to `.pre-commit-config.yaml`, after the `renovate-config-validator` repo block:

```yaml
  - repo: local
    hooks:
      - id: prm-apn-id-tag
        name: PRM aws-apn-id tag present in every layer
        entry: python3 @bin/scripts/prm_tags/check.py --root .
        language: system
        pass_filenames: false
        files: \.tf$
```

`pass_filenames: false` because the check is whole-tree: a new layer is missing the tag regardless of which file the commit touched.

- [ ] **Step 4: Verify the hook runs**

```bash
pre-commit run prm-apn-id-tag --all-files
```

Expected: `PRM aws-apn-id tag present in every layer.........Passed`.

- [ ] **Step 5: Run the full pre-commit suite**

```bash
make pre-commit
```

Expected: all hooks pass. `terraform_fmt` must report no changes — if it rewrites files, `leverage tofu format` was missed somewhere; re-run it and amend.

- [ ] **Step 6: Commit**

```bash
git add Makefile .pre-commit-config.yaml
git commit -m "feat(prm): enforce the aws-apn-id tag in make and pre-commit

Whole-tree check, so a new layer is caught regardless of which file the
commit touched."
```

---

### Task 7: Documentation

**Files:**
- Modify: `CLAUDE.md` (the PRM bullet under "Naming Conventions", and the disabled-layer sentence under "Layer Pattern")

- [ ] **Step 1: Replace the PRM bullet**

Find the bullet beginning `- **PRM compliance tag (\`aws-apn-id\`)**:` and replace it in full with:

```markdown
- **PRM compliance tag (`aws-apn-id`)**: Every layer carries it. The value comes from
  `local.prm_apn_id`, defined once in `config/common-variables.tf` and keyed on the account
  (`var.environment`): `data-science` maps to `pc:b6t445987ttlzwgcll8zdt8nv` (*GenAI Assessment for
  Startups*, `prod-zw4ehbg5ayh2m`), every other account to `pc:5k5o9j3cjaqzpbiwt7ww6e65o` (*Leverage
  | AWS Modernization (Containers / Serverless)*, `prod-pkadanxklqjdc`). **Never hardcode a `pc:`
  literal in a layer** — add the line as `"aws-apn-id" = local.prm_apn_id` and let the map decide.
  `make prm-tags` enforces this; genuinely untaggable layers live in
  `@bin/scripts/prm_tags/allowlist.txt` with a reason.
  - **Only Public, Active listings are valid targets.** Several binbash listings are `Restricted`,
    which is de-listed and does not satisfy AWS's "at least one public listing" requirement. Check
    before adopting a new code:
    ```bash
    aws marketplace-catalog describe-entity --catalog AWSMarketplace --entity-id prod-xxxxxxxxxxxxx \
      --query 'DetailsDocument.[Description.ProductCode,Description.Visibility]' --output text
    ```
  - **Bedrock model invocations are not covered by resource tagging.** Attribution needs an
    Application Inference Profile tagged with `aws-apn-id`, and works only for Amazon/OSS models —
    Anthropic Claude invocations require the User Agent String method instead. See
    [AWS PRM Bedrock docs](https://docs.aws.amazon.com/PRM/latest/aws-prm-onboarding-guide/bedrock-best-practices.html).
  - PRM covers 90 services, not only AI ones. IAM, Organizations, Identity Center, GuardDuty,
    Config, CloudTrail, Inspector and Macie are **not** among them.
```

- [ ] **Step 2: Correct the disabled-layer convention sentence**

Find the sentence under "Layer Pattern" reading `Directories ending with a space followed by \`--\` suffix ... are **disabled/optional layers**` and replace with:

```markdown
Directories whose name ends in `--` are **disabled/optional layers**, excluded from active
deployment and Atlantis autodiscover. Both forms occur in the tree — spaced (`databases-mysql --`)
and attached (`databases-dynamodb--`) — and one carries a trailing space, so tooling must match
`segment.rstrip().endswith("--")`, as `@bin/scripts/version_support/discover.py` does. Matching only
`" --"` silently treats 11 dormant layers as active.
```

- [ ] **Step 3: Verify no stale prohibition remains**

```bash
grep -n "without explicit Partner Development Manager approval" CLAUDE.md
```

Expected: no output — the old rule is fully replaced.

```bash
grep -c "aws-apn-id" CLAUDE.md
```

Expected: at least 4.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(prm): invert the aws-apn-id rule and fix the disabled-layer suffix

The tag is now the default on every layer, sourced from local.prm_apn_id
rather than hardcoded, so the old 'do not add without PDM approval' rule
is replaced by how to add it correctly.

Also corrects the disabled-layer convention: both '--' forms occur in the
tree and matching only ' --' misses 11 layers."
```

---

### Task 8: Plan verification

**Files:** none modified — this task produces evidence for the PR.

163 layers cannot each be planned by hand. Plan a sample that covers every account and the riskiest resource types.

- [ ] **Step 1: Refresh credentials**

```bash
.venv/bin/leverage aws sso login
.venv/bin/leverage aws sso refresh
```

Expected: `Credential refresh complete: N refreshed, 0 failed.`

- [ ] **Step 2: Plan the sample layers**

One per account, plus the highest-risk resource types:

```bash
for L in management/global/cost-mgmt \
         security/us-east-1/base-identities \
         shared/us-east-1/base-network \
         network/us-east-1/base-network \
         apps-devstg/us-east-1/k8s-eks-demoapps/k8s-eks \
         apps-prd/us-east-1/base-network \
         data-science/us-east-1/bedrock-agentcore ; do
  echo "=============== $L"
  ( cd "$L" && "$OLDPWD/.venv/bin/leverage" tofu plan -no-color 2>&1 | tail -5 )
done
```

- [ ] **Step 3: Assert the plan signature**

For every layer above, the plan must satisfy all three:

1. **No replacements.** Search each plan for `must be replaced`, `forces replacement` and `-/+`. Any hit is a stop condition — report it and do not proceed to the PR.
2. **Only `tags` / `tags_all` attributes change.**
3. **The three Bedrock layers show `No changes.`** They moved from a literal to a local resolving to the identical value, so an empty plan is the proof the map is wired correctly. A non-empty plan there means `var.environment` is resolving differently than Task 2 Step 4 showed.

- [ ] **Step 4: Redact the sample plan output for the PR**

Follow the procedure in CLAUDE.md verbatim — the `awk` extract, then the `sed` redaction to a **new** file, then the `grep` scan that must print nothing. Also redact Route53 zone IDs, ACM certificate UUIDs and any `pgp_key`/password blob by attribute name: the CLAUDE.md `grep` alone has been shown to pass while leaking those.

- [ ] **Step 5: Commit nothing**

This task produces no code. Do not commit `tfplan` binaries.

---

### Task 9: Open the Bedrock follow-up issue

- [ ] **Step 1: Create the issue**

```bash
gh issue create \
  --title "PRM: Bedrock model-invocation spend is not attributed by resource tagging" \
  --label enhancement \
  --body 'Resource tagging attributes Bedrock **infrastructure** spend only. Model-invocation spend attributes solely through an **Application Inference Profile** tagged with `aws-apn-id`, and only for Amazon/OSS models — Anthropic Claude invocations require the **User Agent String** method instead.

So after the ref-arch tagging work, the `data-science` Bedrock layers have their infra attributed while the model spend they exist to drive does not.

Scope to decide:
- create and tag application inference profiles for the Amazon/OSS models we invoke
- route invocations through the profile ARN rather than the model ID
- decide whether the User Agent String method is worth implementing for Claude invocations

Refs: https://docs.aws.amazon.com/PRM/latest/aws-prm-onboarding-guide/bedrock-best-practices.html
Spec: `docs/superpowers/specs/2026-09-16-prm-apn-id-tagging-design.md`'
```

- [ ] **Step 2: Record the issue number** in the PR body under References.

---

### Task 10: Pull request

- [ ] **Step 1: Final full verification**

```bash
make prm-tags && make prm-tags-test && make pre-commit
```

Expected: all three exit 0.

- [ ] **Step 2: Push**

```bash
git push -u origin feat/prm-apn-id-tagging
```

- [ ] **Step 3: Open the PR**

Use the What / Why / References template at `.github/PULL_REQUEST_TEMPLATE.md`. Include:

- the account→product-code table
- the count of layers touched and the count allowlisted, with reasons
- the finding that the originally proposed horizontal listing is `Restricted`
- the redacted sample plan output from Task 8, inside a collapsible `<details>` block with a `text` fence
- a line stating **review only — a human applies after approval**
- the Bedrock follow-up issue number

Do **not** add AI attribution to the commits or the PR body (CLAUDE.md).

- [ ] **Step 4: Do not merge or apply**

Applying is a human step after approval. Atlantis has `automerge: true`, so do not run `atlantis apply` from automation.

---

## Rollback

Everything is additive. To revert: `git revert` the tagging commits and re-run `leverage tofu apply` per layer — tags are removed in place, no resource is recreated. The one stateful change is `aws_ce_cost_allocation_tag`, whose destroy sets the tag back to `Inactive`; historical cost data already collected under the tag is retained by AWS.
