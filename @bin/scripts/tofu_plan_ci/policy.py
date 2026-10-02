"""Conservative eligibility policy for credentialed OpenTofu plans."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path, PurePosixPath
from typing import Sequence


CONTROL_PATH_PREFIXES = (
    ".github/workflows/",
    ".github/actions/",
    "@bin/scripts/tofu_plan_ci/",
)
CONTROL_PATHS = {".github/CODEOWNERS"}

# These constructs can change what code runs during init/plan or where state and
# credentials are sent. A maintainer can still review them through static CI; the
# credentialed job is intentionally suppressed for that PR.
EXECUTION_SENSITIVE_HCL = (
    (re.compile(r"\brequired_providers\b"), "provider requirements changed"),
    (re.compile(r"\brequired_version\b"), "OpenTofu requirements changed"),
    (re.compile(r"\bbackend\s+\""), "backend configuration changed"),
    (re.compile(r"\bprovider\s+\""), "provider configuration changed"),
    (re.compile(r"\bsource\s*="), "module/provider source changed"),
    (re.compile(r"\bdata\s+\"external\""), "external data source changed"),
    (re.compile(r"\bprovisioner\s+\""), "provisioner configuration changed"),
)

EXECUTABLE_HCL_BLOCKS = (
    (re.compile(r"\bdata\s+\"external\""), "changed file contains an external data source"),
    (re.compile(r"\bprovisioner\s+\""), "changed file contains a provisioner"),
    (
        re.compile(r"\bresource\s+\"(?:null_resource|terraform_data)\""),
        "changed file contains an imperative compatibility resource",
    ),
    (re.compile(r"\bprovider\s+\""), "changed file contains provider configuration"),
    (re.compile(r"\bbackend\s+\""), "changed file contains backend configuration"),
)


def git_hcl_patch(root: Path, base: str, head: str) -> str:
    """Return only the HCL patch needed by the policy scanner."""

    proc = subprocess.run(
        [
            "git",
            "diff",
            "--no-ext-diff",
            "--unified=0",
            f"{base}...{head}",
            "--",
            "*.tf",
        ],
        cwd=root,
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return proc.stdout


def changed_hcl_documents(root: Path, changed_paths: Sequence[str]) -> dict[str, str]:
    """Read candidate HCL files so edits inside existing executable blocks are caught."""

    documents: dict[str, str] = {}
    for raw_path in changed_paths:
        path = PurePosixPath(raw_path)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError(f"changed path must be repository-relative: {raw_path!r}")
        candidate = root.joinpath(*path.parts)
        if path.suffix == ".tf" and candidate.is_file() and not candidate.is_symlink():
            documents[path.as_posix()] = candidate.read_text(
                encoding="utf-8", errors="replace"
            )
    return documents


def live_plan_blockers(
    changed_paths: Sequence[str],
    hcl_patch: str = "",
    hcl_documents: dict[str, str] | None = None,
) -> list[str]:
    """Explain why a PR is ineligible to receive temporary AWS credentials."""

    blockers: set[str] = set()
    for raw_path in changed_paths:
        path = PurePosixPath(raw_path).as_posix().removeprefix("./")
        if path in CONTROL_PATHS or path.startswith(CONTROL_PATH_PREFIXES):
            blockers.add(f"CI control-plane file changed: {path}")
        if path.endswith("/.terraform.lock.hcl") or path == ".terraform.lock.hcl":
            blockers.add(f"provider lock file changed: {path}")
        if PurePosixPath(path).name == "config.tf":
            blockers.add(f"layer execution configuration changed: {path}")

    if hcl_documents is not None:
        documented = set(hcl_documents)
        for raw_path in changed_paths:
            path = PurePosixPath(raw_path).as_posix().removeprefix("./")
            if path.endswith(".tf") and path not in documented:
                blockers.add(f"changed HCL file is absent, unreadable, or a symlink: {path}")

    for line in hcl_patch.splitlines():
        if not line.startswith(("+", "-")) or line.startswith(("+++", "---")):
            continue
        content = line[1:]
        for pattern, reason in EXECUTION_SENSITIVE_HCL:
            if pattern.search(content):
                blockers.add(reason)

    for path, document in (hcl_documents or {}).items():
        for pattern, reason in EXECUTABLE_HCL_BLOCKS:
            if pattern.search(document):
                blockers.add(f"{reason}: {path}")

    return sorted(blockers)
