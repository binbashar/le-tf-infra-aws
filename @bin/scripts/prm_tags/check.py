#!/usr/bin/env python3
"""Assert every OpenTofu layer carries the PRM `aws-apn-id` tag.

PRM (AWS Partner Revenue Measurement) attributes AWS consumption to an AWS
Marketplace listing through the cost allocation tag `aws-apn-id`. A layer that
omits it drives spend that is never attributed to binbash -- invisible at plan
time and at apply time, which is exactly why it needs a static check.

Every layer is checked, disabled ones included: they are tagged too, so that
enabling a layer never silently starts unattributed spend. Layers that create
nothing taggable (Organizations, Identity Center, IAM-only, Kubernetes/Helm)
are listed in allowlist.txt with a reason.

Stdlib only, no AWS credentials, no network. Run from the repository root:

    python3 @bin/scripts/prm_tags/check.py --root .
"""

from __future__ import annotations

import argparse
import os
import re
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

    Symlinks are skipped. Every layer symlinks common-variables.tf to the
    shared config/common-variables.tf, which documents the tag key in a
    comment -- following it would make all 161 linked layers pass regardless
    of their own contents. A layer has to carry the tag in its own files.
    """
    for name in sorted(os.listdir(layer_path)):
        if not name.endswith(".tf"):
            continue
        full = os.path.join(layer_path, name)
        if os.path.islink(full) or not os.path.isfile(full):
            continue
        with open(full, encoding="utf-8", errors="ignore") as handle:
            if TAG_KEY in handle.read():
                return True
    return False


# `tags = local.tags`, `tags = merge(local.tags, ...)`, or a provider
# `default_tags` block. default_tags is the only one that reaches resources
# inside modules that expose no `tags` variable of their own.
_CONSUMED = re.compile(r'tags\s*=\s*(local\.tags|merge\s*\(\s*local\.tags)|default_tags')


def tags_are_consumed(layer_path: str) -> bool:
    """True when the layer actually attaches local.tags to something.

    A layer can define local.tags with the PRM key and never pass it to any
    resource, module or provider. It then satisfies has_prm_tag() while
    attributing nothing -- the failure mode this catches.
    """
    for name in sorted(os.listdir(layer_path)):
        if not name.endswith(".tf"):
            continue
        full = os.path.join(layer_path, name)
        if os.path.islink(full) or not os.path.isfile(full):
            continue
        with open(full, encoding="utf-8", errors="ignore") as handle:
            if _CONSUMED.search(handle.read()):
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
    missing, inert = [], []
    for rel in sorted(layer_dirs(args.root)):
        if rel in allowed:
            continue
        path = os.path.join(args.root, rel)
        if not has_prm_tag(path):
            missing.append(rel)
        elif not tags_are_consumed(path):
            inert.append(rel)

    if inert:
        print(f"{len(inert)} layer(s) define the '{TAG_KEY}' tag but never attach it:\n")
        for rel in inert:
            print(f"  {rel}")
        print("\nPass `tags = local.tags` to the layer's resources/modules, or add")
        print("`default_tags { tags = local.tags }` to its provider. If the layer creates")
        print("nothing taggable, drop the tag line and allowlist it with that reason.\n")

    if missing:
        print(f"{len(missing)} layer(s) missing the PRM '{TAG_KEY}' tag:\n")
        for rel in missing:
            print(f"  {rel}")
        print(f'\nAdd `"{TAG_KEY}" = local.prm_apn_id` to the layer\'s local.tags map,')
        print("or add the layer to @bin/scripts/prm_tags/allowlist.txt with a reason.")

    if missing or inert:
        return 1

    print(f"OK - every layer carries the PRM '{TAG_KEY}' tag and attaches it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
