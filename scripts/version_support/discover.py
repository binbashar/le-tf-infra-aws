"""Discover Kubernetes and database engine version pins in the OpenTofu tree.

Pure filesystem + HCL parsing. This module never calls AWS.
"""

from __future__ import annotations

import glob
import os
import re
from dataclasses import dataclass

import hcl2
from hcl2.utils import SerializationOptions

# python-hcl2 v8 keeps surrounding quotes on keys and string values and injects
# __is_block__ / __comments__ metadata keys into the parsed dicts. These options
# give plain Python values.
OPTS = SerializationOptions(
    with_comments=False,
    explicit_blocks=False,
    strip_string_quotes=True,
)


def is_disabled_layer(path: str) -> bool:
    """True when any path segment marks the layer disabled.

    Both suffix forms occur in this repo and the rule must match both:
    ``databases-mysql --`` (spaced) and ``databases-dynamodb--`` (attached).
    Matching on ``" --"`` would silently treat the attached form as active and
    hard-fail PRs on dormant infrastructure.

    Trailing whitespace in a segment is stripped before the suffix check, so
    ``databases-mysql -- `` is detected too -- the ``.rstrip()`` is load-bearing,
    not decorative.
    """
    return any(
        segment.rstrip().endswith("--")
        for segment in path.replace("\\", "/").split("/")
        if segment
    )


def line_of(path: str, key: str) -> int | None:
    """1-indexed line where `key` is assigned or declared, or None.

    python-hcl2 gives no line numbers under OPTS (``with_meta`` is ignored when
    ``explicit_blocks`` is off), so findings get their line from a text scan.
    """
    patterns = (
        re.compile(rf"^\s*{re.escape(key)}\s*="),
        re.compile(rf'^\s*variable\s+"{re.escape(key)}"'),
    )
    try:
        with open(path, encoding="utf-8") as handle:
            for number, line in enumerate(handle, 1):
                if any(pattern.match(line) for pattern in patterns):
                    return number
    except OSError:
        return None
    return None


def load_layer(layer_dir: str) -> tuple[dict[str, dict], list[str]]:
    """Parse every ``*.tf`` in one layer. Returns (docs_by_path, parse_errors).

    A file that fails to parse is recorded and skipped; the scan continues so one
    malformed file never blinds the whole run.
    """
    docs: dict[str, dict] = {}
    errors: list[str] = []
    for path in sorted(glob.glob(os.path.join(layer_dir, "*.tf"))):
        try:
            with open(path, encoding="utf-8") as handle:
                docs[path] = hcl2.load(handle, serialization_options=OPTS)
        except Exception as exc:  # noqa: BLE001 - any parse failure is reportable
            errors.append(f"{path}: {exc}")
    return docs, errors


# Strict anchoring on purpose: only a whole-string "${var.x}" / "${local.x}" is a
# reference. Partial ("${var.x}-suffix"), spaced ("${ var.x }"), attribute access
# ("${local.x.y}") and module refs fall through as literals. For a *version* that is
# safe -- AWS returns nothing for the bogus string, so it surfaces as UNKNOWN and is
# warned rather than passing silently. For an *engine* it means the block is skipped,
# which is the same treatment a non-database module gets. Widen this only with a test
# covering the form you are adding.
_INTERPOLATION = re.compile(r"^\$\{(var|local)\.([A-Za-z0-9_-]+)\}$")


@dataclass(frozen=True)
class Resolution:
    """A dereferenced HCL value plus where it came from."""

    value: object | None
    how: str  # "literal" | "var.<n>" | "var.<n> (tfvars)" | "local.<n>" | "unresolved"
    origin: str | None = None  # file that defines the value, for var/local


class Resolver:
    """Dereferences ``${var.x}`` and ``${local.x}`` within a single layer.

    Locals are not optional: ``databases-aurora-pgsql --`` declares
    ``engine = local.engine``, so a var-only resolver would fail the engine
    allow-list and skip the layer entirely.
    """

    def __init__(self, docs: dict[str, dict], tfvars: dict | None = None) -> None:
        self.tfvars = tfvars or {}
        self.variables: dict[str, tuple[object, str]] = {}
        self.locals: dict[str, tuple[object, str]] = {}
        for path, doc in docs.items():
            for block in doc.get("variable", []):
                for name, body in block.items():
                    if isinstance(body, dict) and "default" in body:
                        self.variables[name] = (body["default"], path)
            for block in doc.get("locals", []):
                for name, value in block.items():
                    self.locals[name] = (value, path)

    def resolve(self, value: object) -> Resolution:
        if value is None:
            return Resolution(None, "unresolved")
        if not isinstance(value, str):
            return Resolution(value, "literal")
        match = _INTERPOLATION.match(value.strip())
        if match is None:
            return Resolution(value, "literal")

        scope, name = match.group(1), match.group(2)
        if scope == "var":
            if name in self.tfvars:
                return Resolution(self.tfvars[name], f"var.{name} (tfvars)")
            if name in self.variables:
                default, path = self.variables[name]
                return Resolution(default, f"var.{name}", path)
            return Resolution(None, "unresolved")

        if name in self.locals:
            local_value, path = self.locals[name]
            return Resolution(local_value, f"local.{name}", path)
        return Resolution(None, "unresolved")


# Only these carry an RDS/Aurora extended-support surcharge. elasticache, OpenSearch
# and DMS are excluded structurally - their engine value is never in this set.
RDS_ENGINES = frozenset({"mysql", "postgres", "aurora-mysql", "aurora-postgresql"})

# rds:DescribeDBMajorEngineVersions takes a MAJOR version, and the mapping differs
# by family: MySQL majors are "major.minor" (8.0, 5.7), PostgreSQL majors are the
# leading component only (14, 16).
_MYSQL_FAMILY = frozenset({"mysql", "aurora-mysql"})


def major_version(engine: str, version: str) -> str:
    """Major version string accepted by rds:DescribeDBMajorEngineVersions."""
    parts = version.split(".")
    if engine in _MYSQL_FAMILY:
        return ".".join(parts[:2])
    return parts[0]


@dataclass(frozen=True)
class Pin:
    """One version pinned in the tree."""

    kind: str  # "eks" | "rds"
    engine: str | None  # None for EKS
    version: str | None  # None when unresolvable
    major_version: str | None  # what the AWS lookup is keyed on
    layer: str  # repo-relative layer directory
    active: bool  # False when the layer is disabled
    source: str  # "path/file.tf:12 (var.cluster_version)"


_SKIP_PATH_PARTS = (
    os.sep + ".terraform",
    os.sep + ".infracost",
    os.sep + ".git" + os.sep,
    os.sep + "docs" + os.sep,
    # Without this, scanning the repo root would pick up this package's own
    # fixture tree and report three fabricated pins.
    os.sep + "fixtures" + os.sep,
)


def _layer_dirs(root: str) -> list[str]:
    """Every directory under `root` containing at least one .tf file."""
    directories = set()
    for path in glob.iglob(os.path.join(root, "**", "*.tf"), recursive=True):
        # Skip-check against the path RELATIVE to `root`, not the raw glob match.
        # discover(FIXTURE_TREE) is called with a root that itself sits inside a
        # directory named "fixtures" (.../tests/fixtures/tree) -- checking the raw
        # path would make every fixture file contain "/fixtures/" and skip the
        # whole tree. Relativizing first means the entry only fires when
        # "fixtures" appears *within* the scanned tree, e.g. when root is the repo
        # root and this package's own fixture tree is nested underneath it.
        relative = os.sep + os.path.relpath(path, root)
        if any(part in relative for part in _SKIP_PATH_PARTS):
            continue
        directories.add(os.path.dirname(path))
    return sorted(directories)


def _blocks(doc: dict):
    """Yield every module and resource block body in a parsed document."""
    for block in doc.get("module", []):
        for name, body in block.items():
            if isinstance(body, dict):
                yield body
    for block in doc.get("resource", []):
        for _type, named in block.items():
            if not isinstance(named, dict):
                continue
            for name, body in named.items():
                if isinstance(body, dict):
                    yield body


def load_tfvars(root: str, layer: str) -> tuple[dict, list[str]]:
    """Merge config/common.tfvars and {account}/config/account.tfvars.

    Returns (merged_vars, parse_errors). Failures are REPORTED, never swallowed:
    silently degrading to "no overrides" would resolve a pin to its variables.tf
    default while a tfvars override supplies the real version -- a false negative,
    which is the one failure mode this tool must not have.
    """
    account = layer.replace("\\", "/").split("/")[0]
    merged: dict = {}
    errors: list[str] = []
    candidates = (
        os.path.join(root, "config", "common.tfvars"),
        os.path.join(root, account, "config", "account.tfvars"),
    )
    for path in candidates:
        if not os.path.exists(path):
            continue
        try:
            with open(path, encoding="utf-8") as handle:
                merged.update(hcl2.load(handle, serialization_options=OPTS))
        except Exception as exc:  # noqa: BLE001 - any parse failure is reportable
            errors.append(f"{path}: {exc}")
    return merged, errors


def _source(reference_path: str, key: str, resolution: Resolution, root: str) -> str:
    """Human-actionable 'file:line (how)' for a pin."""
    if resolution.how == "literal":
        target, lookup = reference_path, key
    else:
        target = resolution.origin or reference_path
        lookup = resolution.how.split()[0].split(".")[-1]

    line = line_of(target, lookup) or line_of(target, key)
    relative = os.path.relpath(target, root)
    where = f"{relative}:{line}" if line else relative
    return where if resolution.how == "literal" else f"{where} ({resolution.how})"


def discover(root: str) -> tuple[list[Pin], list[str]]:
    """Walk `root` and return (pins, parse_errors)."""
    pins: list[Pin] = []
    errors: list[str] = []

    for layer_dir in _layer_dirs(root):
        docs, layer_errors = load_layer(layer_dir)
        errors.extend(layer_errors)
        if not docs:
            continue

        layer = os.path.relpath(layer_dir, root)
        active = not is_disabled_layer(layer)
        tfvars, tfvars_errors = load_tfvars(root, layer)
        errors.extend(tfvars_errors)
        resolver = Resolver(docs, tfvars=tfvars)

        for path, doc in docs.items():
            for body in _blocks(doc):
                if "cluster_version" in body:
                    resolution = resolver.resolve(body["cluster_version"])
                    version = resolution.value if isinstance(resolution.value, str) else None
                    pins.append(
                        Pin(
                            kind="eks",
                            engine=None,
                            version=version,
                            major_version=version,
                            layer=layer,
                            active=active,
                            source=_source(path, "cluster_version", resolution, root),
                        )
                    )

                if "engine" not in body:
                    continue
                engine = resolver.resolve(body["engine"]).value
                # An engine that will not resolve drops the block, same as a
                # non-database module. Deliberate asymmetry with engine_version,
                # which yields a Pin that surfaces as UNKNOWN: an unrecognised
                # engine is far more likely to be "not a database" than "a database
                # we failed to read".
                if engine not in RDS_ENGINES:
                    continue

                version_resolution = resolver.resolve(body.get("engine_version"))
                version = (
                    version_resolution.value
                    if isinstance(version_resolution.value, str)
                    else None
                )

                major = None
                if "major_engine_version" in body:
                    explicit = resolver.resolve(body["major_engine_version"]).value
                    major = explicit if isinstance(explicit, str) else None
                if major is None and version is not None:
                    major = major_version(engine, version)

                pins.append(
                    Pin(
                        kind="rds",
                        engine=engine,
                        version=version,
                        major_version=major,
                        layer=layer,
                        active=active,
                        source=_source(path, "engine_version", version_resolution, root),
                    )
                )

    return pins, errors
