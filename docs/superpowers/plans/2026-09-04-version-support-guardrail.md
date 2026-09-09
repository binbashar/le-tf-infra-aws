# Version-Support Guardrail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a scanner that reads Kubernetes and database engine versions pinned in this repo's `.tf` files, asks AWS for each version's support lifecycle, fails PRs that pin an active layer into extended support, and sweeps weekly for versions approaching the cliff.

**Architecture:** Three pure-boundary Python modules — `discover.py` (tree → `[Pin]`, never calls AWS), `lifecycle.py` (`[Pin]` → `[Finding]`, never reads the filesystem), `report.py` (pure formatting) — behind a `__main__.py` CLI with three modes. One GitHub Actions workflow runs it on PRs and weekly. Side effects (Slack, GitHub issue) live in the workflow, not the scanner, so `report.py` stays pure.

**Tech Stack:** Python 3.12, `python-hcl2` 8.x, `boto3` 1.43+, pytest, `botocore.stub.Stubber`, GitHub Actions.

> **On test counts:** steps say "all green" rather than an absolute total. Most tests here are
> `@pytest.mark.parametrize`d, so the collected count is larger than the number of `def test_`
> functions and drifts as cases are added. Assert the suite is green, not that it reports a
> particular number.

**Spec:** `docs/superpowers/specs/2026-09-03-version-support-guardrail-design.md`

---

## Ground truth established before this plan

These were verified by running code against this repository — do not re-derive them:

| Fact | Value |
| --- | --- |
| Real pins in tree | **6**: 1 EKS (`1.34` via `var.cluster_version`), 5 RDS/Aurora (all in disabled layers) |
| `python-hcl2` v8 default output | Keeps quotes (`'"1.34"'`), injects `__is_block__` / `__comments__` — **must** be configured away |
| `with_meta=True` | Yields **no** line numbers under our options; lines come from a text scan |
| Aurora pgsql engine | `"${local.engine}"` — **locals resolution is mandatory** |
| `elasticache-redis` | Has `engine_version` but **no `engine`** key → excluded structurally |
| `eks:DescribeClusterVersions` params | `clusterVersions` and `includeAll` are **mutually exclusive** — pass `includeAll` alone and filter locally, then paginate |
| EKS version argument | `cluster_version` (terraform-aws-eks v20) **and** `kubernetes_version` (v21) — both must match |
| EKS `versionStatus` enum | `UNSUPPORTED` \| `STANDARD_SUPPORT` \| `EXTENDED_SUPPORT` |
| RDS `LifecycleSupportName` enum | `open-source-rds-standard-support` \| `open-source-rds-extended-support` (**lowercase-hyphenated**) |
| Disabled-layer suffix | Both ` --` (spaced) and `--` (attached) occur — match trailing `--` |

---

## File Structure

| File | Responsibility |
| --- | --- |
| `@bin/scripts/version_support/__init__.py` | Package marker (docstring only — consumers import from the submodules directly) |
| `@bin/scripts/version_support/discover.py` | Tree → `[Pin]`. HCL parsing, reference resolution, engine allow-list. No AWS. |
| `@bin/scripts/version_support/lifecycle.py` | `[Pin]` → `[Finding]`. AWS lookups + severity classification. No filesystem. |
| `@bin/scripts/version_support/report.py` | `[Finding]` → terminal table, GH annotations, markdown, Slack text, issue body. Pure. |
| `@bin/scripts/version_support/__main__.py` | CLI, mode dispatch, exit codes. The only place that decides failure. |
| `@bin/scripts/version_support/requirements.txt` | `python-hcl2`, `boto3` |
| `@bin/scripts/version_support/tests/` | pytest suite + fixture `.tf` tree |
| `.github/workflows/version-support.yml` | PR gate + weekly cron; owns Slack and `gh issue` side effects |
| `docs/version-support/README.md` | Why, upgrade cadence, how to run, IAM |
| `docs/version-support/status.md` | Generated table |
| `Makefile` | `version-support`, `version-support-table` targets |

---

## Task 1: Package scaffold and dependencies

**Files:**
- Create: `@bin/scripts/version_support/__init__.py`
- Create: `@bin/scripts/version_support/requirements.txt`
- Create: `@bin/scripts/version_support/tests/__init__.py`
- Create: `@bin/scripts/version_support/tests/test_smoke.py`

- [ ] **Step 1: Create the package files**

`@bin/scripts/version_support/requirements.txt`:

```text
python-hcl2>=8.1.0,<9
boto3>=1.43.0
```

`@bin/scripts/version_support/__init__.py`:

```python
"""Version-support guardrail: detect EKS/RDS versions heading into extended support.

See docs/superpowers/specs/2026-09-03-version-support-guardrail-design.md
"""
```

`@bin/scripts/version_support/tests/__init__.py`: empty file.

- [ ] **Step 2: Write the smoke test**

`@bin/scripts/version_support/tests/test_smoke.py`:

```python
def test_dependencies_import():
    import boto3
    import hcl2
    from hcl2.utils import SerializationOptions

    assert SerializationOptions().strip_string_quotes is False
```

- [ ] **Step 3: Create the venv and install**

```bash
python3 -m venv .venv-version-support
./.venv-version-support/bin/pip install -q -r @bin/scripts/version_support/requirements.txt pytest
```

- [ ] **Step 4: Run the test**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_smoke.py -v`
Expected: PASS

- [ ] **Step 5: Ignore the venv and commit**

Add `.venv-version-support/` to `.gitignore`, then:

```bash
git add .gitignore @bin/scripts/version_support/
git commit -m "feat(version-support): scaffold the guardrail package"
```

---

## Task 2: The disabled-layer rule

**Files:**
- Create: `@bin/scripts/version_support/discover.py`
- Create: `@bin/scripts/version_support/tests/test_discover.py`

- [ ] **Step 1: Write the failing test**

`@bin/scripts/version_support/tests/test_discover.py`:

```python
import pytest

from version_support.discover import is_disabled_layer


@pytest.mark.parametrize(
    "path",
    [
        "apps-devstg/us-east-1/databases-mysql --",          # spaced form
        "apps-devstg/us-east-1/databases-dynamodb--",        # attached form
        "data-science/us-east-1/databases-aurora-mysql--",
        "apps-devstg/us-east-1/databases-mysql --/nested",   # disabled parent
    ],
)
def test_disabled_layers_are_detected(path):
    assert is_disabled_layer(path) is True


@pytest.mark.parametrize(
    "path",
    [
        "apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
        "apps-devstg/us-east-1/elasticache-redis",
        "management/global/organizations",
    ],
)
def test_active_layers_are_not_disabled(path):
    assert is_disabled_layer(path) is False
```

- [ ] **Step 2: Run test to verify it fails**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_discover.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'version_support.discover'`

- [ ] **Step 3: Write minimal implementation**

`@bin/scripts/version_support/discover.py`:

```python
"""Discover Kubernetes and database engine version pins in the OpenTofu tree.

Pure filesystem + HCL parsing. This module never calls AWS.
"""

from __future__ import annotations

import os


def is_disabled_layer(path: str) -> bool:
    """True when any path segment marks the layer disabled.

    Both suffix forms occur in this repo and the rule must match both:
    ``databases-mysql --`` (spaced) and ``databases-dynamodb--`` (attached).
    Matching on ``" --"`` would silently treat the attached form as active and
    hard-fail PRs on dormant infrastructure.
    """
    return any(
        segment.rstrip().endswith("--")
        for segment in path.replace("\\", "/").split("/")
        if segment
    )
```

- [ ] **Step 4: Run test to verify it passes**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_discover.py -v`
Expected: PASS (all green)

- [ ] **Step 5: Commit**

```bash
git add @bin/scripts/version_support/discover.py @bin/scripts/version_support/tests/test_discover.py
git commit -m "feat(version-support): detect disabled layers by trailing --"
```

---

## Task 3: HCL loading and line lookup

**Files:**
- Modify: `@bin/scripts/version_support/discover.py`
- Modify: `@bin/scripts/version_support/tests/test_discover.py`
- Create: `@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/k8s-eks-demoapps/cluster/main.tf`
- Create: `@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/k8s-eks-demoapps/cluster/variables.tf`

- [ ] **Step 1: Create the fixture layer**

`@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/k8s-eks-demoapps/cluster/main.tf`:

```hcl
module "cluster" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v21.0.0"

  cluster_name    = "test"
  cluster_version = var.cluster_version
}
```

`@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/k8s-eks-demoapps/cluster/variables.tf`:

```hcl
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.31"
}
```

- [ ] **Step 2: Write the failing test**

Append to `@bin/scripts/version_support/tests/test_discover.py`:

```python
import os

from version_support.discover import line_of, load_layer

FIXTURE_TREE = os.path.join(os.path.dirname(__file__), "fixtures", "tree")
EKS_LAYER = os.path.join(
    FIXTURE_TREE, "apps-devstg", "us-east-1", "k8s-eks-demoapps", "cluster"
)


def test_load_layer_strips_quotes_and_metadata():
    docs, errors = load_layer(EKS_LAYER)

    assert errors == []
    variables = docs[os.path.join(EKS_LAYER, "variables.tf")]["variable"]
    # python-hcl2 v8 would give '"cluster_version"' / '"1.31"' without our options.
    assert variables[0]["cluster_version"]["default"] == "1.31"
    assert "__comments__" not in docs[os.path.join(EKS_LAYER, "variables.tf")]


def test_line_of_finds_attribute_and_variable_block():
    assert line_of(os.path.join(EKS_LAYER, "main.tf"), "cluster_version") == 5
    assert line_of(os.path.join(EKS_LAYER, "variables.tf"), "cluster_version") == 1
    assert line_of(os.path.join(EKS_LAYER, "main.tf"), "nope") is None
```

- [ ] **Step 3: Run test to verify it fails**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_discover.py -v`
Expected: FAIL with `ImportError: cannot import name 'line_of'`

- [ ] **Step 4: Write the implementation**

Add to the imports at the top of `@bin/scripts/version_support/discover.py`:

```python
import glob
import re

import hcl2
from hcl2.utils import SerializationOptions

# python-hcl2 v8 keeps surrounding quotes on keys and string values and injects
# __is_block__ / __comments__ metadata. These options give plain Python values.
OPTS = SerializationOptions(
    with_comments=False,
    explicit_blocks=False,
    strip_string_quotes=True,
)
```

Then append:

```python
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
```

- [ ] **Step 5: Run test to verify it passes**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_discover.py -v`
Expected: PASS (all green)

- [ ] **Step 6: Commit**

```bash
git add @bin/scripts/version_support/
git commit -m "feat(version-support): load layer HCL with quote-stripping options"
```

---

## Task 4: Reference resolution (literal, var, local, tfvars)

**Files:**
- Modify: `@bin/scripts/version_support/discover.py`
- Modify: `@bin/scripts/version_support/tests/test_discover.py`
- Create: `@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/databases-aurora-pgsql --/cluster.tf`
- Create: `@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/databases-aurora-pgsql --/locals.tf`

- [ ] **Step 1: Create the Aurora fixture (the locals case)**

`@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/databases-aurora-pgsql --/locals.tf`:

```hcl
locals {
  engine = "aurora-postgresql"
}
```

`@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/databases-aurora-pgsql --/cluster.tf`:

```hcl
module "aurora_postgresql" {
  source = "github.com/terraform-aws-modules/terraform-aws-rds-aurora.git?ref=v9.0.0"

  engine         = local.engine
  engine_version = "14.8"
}
```

- [ ] **Step 2: Write the failing test**

Append to `@bin/scripts/version_support/tests/test_discover.py`:

```python
from version_support.discover import Resolver

AURORA_LAYER = os.path.join(
    FIXTURE_TREE, "apps-devstg", "us-east-1", "databases-aurora-pgsql --"
)


def test_resolver_returns_literals_unchanged():
    resolver = Resolver({}, tfvars={})
    resolution = resolver.resolve("mysql")

    assert resolution.value == "mysql"
    assert resolution.how == "literal"


def test_resolver_dereferences_a_variable_default():
    docs, _ = load_layer(EKS_LAYER)
    resolver = Resolver(docs, tfvars={})

    resolution = resolver.resolve("${var.cluster_version}")

    assert resolution.value == "1.31"
    assert resolution.how == "var.cluster_version"
    assert resolution.origin.endswith("variables.tf")


def test_tfvars_override_beats_the_variable_default():
    docs, _ = load_layer(EKS_LAYER)
    resolver = Resolver(docs, tfvars={"cluster_version": "1.29"})

    resolution = resolver.resolve("${var.cluster_version}")

    # Reporting the default while a tfvars override supplies the real value
    # would be a false negative - the one failure this guardrail must not have.
    assert resolution.value == "1.29"
    assert resolution.how == "var.cluster_version (tfvars)"


def test_resolver_dereferences_a_local():
    docs, _ = load_layer(AURORA_LAYER)
    resolver = Resolver(docs, tfvars={})

    resolution = resolver.resolve("${local.engine}")

    assert resolution.value == "aurora-postgresql"
    assert resolution.how == "local.engine"


def test_unresolvable_reference_is_never_assumed_safe():
    resolver = Resolver({}, tfvars={})

    assert resolver.resolve("${var.missing}").how == "unresolved"
    assert resolver.resolve("${var.missing}").value is None
    assert resolver.resolve(None).how == "unresolved"
```

- [ ] **Step 3: Run test to verify it fails**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_discover.py -v`
Expected: FAIL with `ImportError: cannot import name 'Resolver'`

- [ ] **Step 4: Write the implementation**

Add to the imports of `@bin/scripts/version_support/discover.py`:

```python
from dataclasses import dataclass
```

Then append:

```python
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
```

- [ ] **Step 5: Run test to verify it passes**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_discover.py -v`
Expected: PASS (all green)

- [ ] **Step 6: Commit**

```bash
git add @bin/scripts/version_support/
git commit -m "feat(version-support): resolve var, local and tfvars references"
```

---

## Task 5: RDS major-version derivation

**Files:**
- Modify: `@bin/scripts/version_support/discover.py`
- Modify: `@bin/scripts/version_support/tests/test_discover.py`

- [ ] **Step 1: Write the failing test**

Append to `@bin/scripts/version_support/tests/test_discover.py`:

```python
from version_support.discover import major_version


@pytest.mark.parametrize(
    ("engine", "version", "expected"),
    [
        ("mysql", "8.0.41", "8.0"),          # MySQL family keeps major.minor
        ("aurora-mysql", "5.7", "5.7"),
        ("aurora-mysql", "8.0.mysql_aurora.3.04.0", "8.0"),
        ("postgres", "14.18", "14"),         # PostgreSQL family keeps major only
        ("aurora-postgresql", "14.8", "14"),
        ("postgres", "16", "16"),
    ],
)
def test_major_version_is_engine_specific(engine, version, expected):
    assert major_version(engine, version) == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_discover.py -k major -v`
Expected: FAIL with `ImportError: cannot import name 'major_version'`

- [ ] **Step 3: Write the implementation**

Append to `@bin/scripts/version_support/discover.py`:

```python
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_discover.py -k major -v`
Expected: PASS (all green)

- [ ] **Step 5: Commit**

```bash
git add @bin/scripts/version_support/
git commit -m "feat(version-support): derive RDS major versions per engine family"
```

---

## Task 6: Pin extraction — EKS, RDS, and the look-alikes

**Files:**
- Modify: `@bin/scripts/version_support/discover.py`
- Modify: `@bin/scripts/version_support/tests/test_discover.py`
- Create: `@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/databases-mysql --/db.tf`
- Create: `@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/elasticache-redis/main.tf`
- Create: `@bin/scripts/version_support/tests/fixtures/tree/data-science/us-east-1/datalake--/dms.tf`
- Create: `@bin/scripts/version_support/tests/fixtures/tree/config/common.tfvars`
- Create: `@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/config/account.tfvars`

> **Amendment (found during execution).** Two conflicts in this task's literal instructions were
> caught by TDD and corrected in the code above and below:
>
> 1. **`_layer_dirs` skipped its own fixture tree.** The original code matched `_SKIP_PATH_PARTS`
>    against the raw glob path. The pre-execution prototype only ever called
>    `discover(<repo root>)`, but the tests below call `discover(FIXTURE_TREE)` — a root that
>    itself sits inside `.../fixtures/`, so every fixture path contained `/fixtures/` and the whole
>    tree was skipped. The plan's code and the plan's tests could not both pass. Fixed by
>    relativizing to `root` before matching.
> 2. **`.gitignore` swallows the `common.tfvars` fixture.** Line 100 is an unanchored
>    `*common.tfvars` — the rule that keeps the real `config/common.tfvars` (which holds AWS
>    account IDs) out of git. It also matches the fixture of the same name, so a plain
>    `git add @bin/scripts/version_support/` drops that file silently, with no error. Force-add it
>    (`git add -f <path>`); once tracked, later edits stage normally.

- [ ] **Step 1: Create the remaining fixtures**

`@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/databases-mysql --/db.tf`:

```hcl
module "mysql_db" {
  source = "github.com/terraform-aws-modules/terraform-aws-rds.git?ref=v6.0.0"

  engine               = "mysql"
  engine_version       = "8.0.41"
  major_engine_version = "8.0"
}
```

`@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/us-east-1/elasticache-redis/main.tf` — a look-alike with `engine_version` but no `engine`:

```hcl
module "elasticache_redis" {
  source = "github.com/terraform-aws-modules/terraform-aws-elasticache.git?ref=v1.0.0"

  engine_version = var.engine_version
}
```

`@bin/scripts/version_support/tests/fixtures/tree/data-science/us-east-1/datalake--/dms.tf` — a look-alike with a similarly-named key:

```hcl
module "dms" {
  source = "github.com/terraform-aws-modules/terraform-aws-dms.git?ref=v2.0.0"

  repl_instance_engine_version = "3.5.3"
}
```

`@bin/scripts/version_support/tests/fixtures/tree/config/common.tfvars`:

```hcl
project = "bb"
```

`@bin/scripts/version_support/tests/fixtures/tree/apps-devstg/config/account.tfvars`:

```hcl
environment = "apps-devstg"
```

- [ ] **Step 2: Write the failing test**

Append to `@bin/scripts/version_support/tests/test_discover.py`:

```python
from version_support.discover import discover


def _by_layer(pins):
    return {pin.layer.replace(os.sep, "/"): pin for pin in pins}


def test_discover_finds_every_real_pin_shape():
    pins, errors = discover(FIXTURE_TREE)

    assert errors == []
    found = _by_layer(pins)
    assert set(found) == {
        "apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
        "apps-devstg/us-east-1/databases-mysql --",
        "apps-devstg/us-east-1/databases-aurora-pgsql --",
    }


def test_discover_resolves_the_eks_variable_default():
    pins, _ = discover(FIXTURE_TREE)
    pin = _by_layer(pins)["apps-devstg/us-east-1/k8s-eks-demoapps/cluster"]

    assert pin.kind == "eks"
    assert pin.engine is None
    assert pin.version == "1.31"
    assert pin.active is True
    assert "var.cluster_version" in pin.source


def test_discover_resolves_the_aurora_engine_from_a_local():
    pins, _ = discover(FIXTURE_TREE)
    pin = _by_layer(pins)["apps-devstg/us-east-1/databases-aurora-pgsql --"]

    assert pin.kind == "rds"
    assert pin.engine == "aurora-postgresql"
    assert pin.version == "14.8"
    assert pin.major_version == "14"
    assert pin.active is False  # disabled layer


def test_discover_prefers_an_explicit_major_engine_version():
    pins, _ = discover(FIXTURE_TREE)
    pin = _by_layer(pins)["apps-devstg/us-east-1/databases-mysql --"]

    assert pin.engine == "mysql"
    assert pin.version == "8.0.41"
    assert pin.major_version == "8.0"


def test_look_alikes_are_never_matched():
    pins, _ = discover(FIXTURE_TREE)
    layers = {pin.layer.replace(os.sep, "/") for pin in pins}

    # elasticache has engine_version but no engine; dms has a similarly-named key.
    assert "apps-devstg/us-east-1/elasticache-redis" not in layers
    assert "data-science/us-east-1/datalake--" not in layers
```

- [ ] **Step 3: Run test to verify it fails**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_discover.py -k discover -v`
Expected: FAIL with `ImportError: cannot import name 'discover'`

- [ ] **Step 4: Write the implementation**

Append to `@bin/scripts/version_support/discover.py`:

```python
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
```

- [ ] **Step 5: Run test to verify it passes**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_discover.py -v`
Expected: PASS (all green)

- [ ] **Step 6: Verify against the real tree**

Run:

```bash
PYTHONPATH=@bin/scripts ./.venv-version-support/bin/python -c "
from version_support.discover import discover
pins, errors = discover('.')
for p in sorted(pins, key=lambda p: p.layer):
    print(f'{p.kind:4} {str(p.engine):20} {str(p.version):10} active={p.active!s:5} {p.layer}')
print('parse errors:', errors)
"
```

Expected: exactly 6 pins — 1 `eks` (`1.34`, `active=True`) and 5 `rds` (all `active=False`), `parse errors: []`. No `elasticache-redis`, no `datalake-demo--`, no `dynamodb`.

- [ ] **Step 7: Commit**

```bash
git add @bin/scripts/version_support/
git commit -m "feat(version-support): extract EKS and RDS pins from the tree"
```

---

## Task 7: Severity classification (pure, no AWS)

**Files:**
- Create: `@bin/scripts/version_support/lifecycle.py`
- Create: `@bin/scripts/version_support/tests/test_lifecycle.py`

- [ ] **Step 1: Write the failing test**

`@bin/scripts/version_support/tests/test_lifecycle.py`:

```python
from datetime import date

import pytest

from version_support.lifecycle import classify

TODAY = date(2026, 9, 4)


@pytest.mark.parametrize(
    ("status", "end_standard", "expected_severity", "expected_days"),
    [
        ("STANDARD_SUPPORT", date(2027, 6, 1), "OK", 270),
        ("STANDARD_SUPPORT", date(2026, 11, 1), "SOON", 58),
        ("STANDARD_SUPPORT", date(2026, 12, 3), "SOON", 90),      # exactly at the line
        ("STANDARD_SUPPORT", date(2026, 12, 4), "OK", 91),        # one day past it
        ("EXTENDED_SUPPORT", date(2026, 1, 1), "EXTENDED", -246),
        ("UNSUPPORTED", None, "UNSUPPORTED", None),
        ("UNKNOWN", None, "UNKNOWN", None),
    ],
)
def test_classify_severity_boundaries(status, end_standard, expected_severity, expected_days):
    severity, days = classify(status, end_standard, today=TODAY)

    assert severity == expected_severity
    assert days == expected_days


def test_a_past_end_date_is_extended_even_if_status_lags():
    severity, _ = classify("STANDARD_SUPPORT", date(2026, 8, 1), today=TODAY)

    assert severity == "EXTENDED"


def test_lead_days_is_configurable():
    severity, _ = classify("STANDARD_SUPPORT", date(2027, 1, 1), today=TODAY, lead_days=180)

    assert severity == "SOON"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_lifecycle.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'version_support.lifecycle'`

- [ ] **Step 3: Write the implementation**

`@bin/scripts/version_support/lifecycle.py`:

```python
"""Classify version pins against AWS support lifecycles.

Pure logic plus AWS lookups. This module never reads the filesystem.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime

from version_support.discover import Pin

DEFAULT_LEAD_DAYS = 90

# Severities that fail a PR when found on an active layer.
BLOCKING = frozenset({"EXTENDED", "UNSUPPORTED"})


@dataclass(frozen=True)
class Finding:
    pin: Pin
    status: str  # STANDARD_SUPPORT | EXTENDED_SUPPORT | UNSUPPORTED | UNKNOWN
    end_standard: date | None
    end_extended: date | None
    days_left: int | None
    severity: str


def as_date(value) -> date | None:
    """Normalise a boto3 timestamp to a date."""
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    return None


def classify(
    status: str,
    end_standard: date | None,
    today: date,
    lead_days: int = DEFAULT_LEAD_DAYS,
) -> tuple[str, int | None]:
    """Return (severity, days_left_to_end_of_standard_support)."""
    if status == "UNKNOWN":
        return "UNKNOWN", None
    if status == "UNSUPPORTED":
        return "UNSUPPORTED", None

    days = (end_standard - today).days if end_standard else None

    # A past end date wins over a lagging status field: AWS's status can trail the
    # transition, but the surcharge is billing either way.
    if status == "EXTENDED_SUPPORT" or (days is not None and days < 0):
        return "EXTENDED", days

    # No date and no explicit bad status means we do not know -- and an absence of
    # information must never read as "fine". UNKNOWN warns without failing a PR.
    if days is None:
        return "UNKNOWN", None

    if days <= lead_days:
        return "SOON", days
    return "OK", days
```

- [ ] **Step 4: Run test to verify it passes**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_lifecycle.py -v`
Expected: PASS (all green)

- [ ] **Step 5: Commit**

```bash
git add @bin/scripts/version_support/
git commit -m "feat(version-support): classify pins into support severities"
```

---

## Task 8: AWS lifecycle lookups

**Files:**
- Modify: `@bin/scripts/version_support/lifecycle.py`
- Modify: `@bin/scripts/version_support/tests/test_lifecycle.py`

- [ ] **Step 1: Write the failing test**

Append to `@bin/scripts/version_support/tests/test_lifecycle.py`:

```python
from datetime import datetime

import boto3
from botocore.stub import Stubber

from version_support.lifecycle import eks_lifecycles, rds_lifecycle


def test_eks_lifecycles_maps_versions_to_support_state():
    client = boto3.client("eks", region_name="us-east-1")
    with Stubber(client) as stub:
        stub.add_response(
            "describe_cluster_versions",
            {
                "clusterVersions": [
                    {
                        "clusterVersion": "1.34",
                        "versionStatus": "STANDARD_SUPPORT",
                        "endOfStandardSupportDate": datetime(2027, 3, 23),
                        "endOfExtendedSupportDate": datetime(2028, 3, 23),
                    },
                    {
                        "clusterVersion": "1.28",
                        "versionStatus": "EXTENDED_SUPPORT",
                        "endOfStandardSupportDate": datetime(2024, 11, 26),
                        "endOfExtendedSupportDate": datetime(2025, 11, 26),
                    },
                ]
            },
            {"clusterVersions": ["1.28", "1.34"], "includeAll": True},
        )

        result = eks_lifecycles({"1.34", "1.28"}, client)

    assert result["1.34"] == ("STANDARD_SUPPORT", date(2027, 3, 23), date(2028, 3, 23))
    assert result["1.28"][0] == "EXTENDED_SUPPORT"


def test_rds_lifecycle_derives_status_from_lifecycle_entries():
    client = boto3.client("rds", region_name="us-east-1")
    with Stubber(client) as stub:
        stub.add_response(
            "describe_db_major_engine_versions",
            {
                "DBMajorEngineVersions": [
                    {
                        "Engine": "aurora-mysql",
                        "MajorEngineVersion": "5.7",
                        "SupportedEngineLifecycles": [
                            {
                                "LifecycleSupportName": "open-source-rds-standard-support",
                                "LifecycleSupportStartDate": datetime(2021, 3, 1),
                                "LifecycleSupportEndDate": datetime(2024, 10, 31),
                            },
                            {
                                "LifecycleSupportName": "open-source-rds-extended-support",
                                "LifecycleSupportStartDate": datetime(2024, 11, 1),
                                "LifecycleSupportEndDate": datetime(2027, 10, 31),
                            },
                        ],
                    }
                ]
            },
            {"Engine": "aurora-mysql", "MajorEngineVersion": "5.7"},
        )

        status, end_standard, end_extended = rds_lifecycle(
            "aurora-mysql", "5.7", client, today=TODAY
        )

    assert status == "EXTENDED_SUPPORT"
    assert end_standard == date(2024, 10, 31)
    assert end_extended == date(2027, 10, 31)


def test_rds_lifecycle_returns_unknown_for_an_unlisted_version():
    client = boto3.client("rds", region_name="us-east-1")
    with Stubber(client) as stub:
        stub.add_response(
            "describe_db_major_engine_versions",
            {"DBMajorEngineVersions": []},
            {"Engine": "mysql", "MajorEngineVersion": "99.9"},
        )

        status, end_standard, _ = rds_lifecycle("mysql", "99.9", client, today=TODAY)

    assert status == "UNKNOWN"
    assert end_standard is None
```

- [ ] **Step 2: Run test to verify it fails**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_lifecycle.py -k "eks_lifecycles or rds_lifecycle" -v`
Expected: FAIL with `ImportError: cannot import name 'eks_lifecycles'`

- [ ] **Step 3: Write the implementation**

Append to `@bin/scripts/version_support/lifecycle.py`:

```python
# Verified against the botocore service model - these are lowercase-hyphenated,
# not the SCREAMING_CASE the EKS enum uses.
_RDS_STANDARD = "open-source-rds-standard-support"
_RDS_EXTENDED = "open-source-rds-extended-support"


def eks_lifecycles(versions: set[str], client) -> dict[str, tuple]:
    """{version: (status, end_standard, end_extended)} for the given k8s versions.

    ``includeAll=True`` is required: without it AWS omits versions that have
    already left standard support, which are exactly the ones we care about.
    """
    if not versions:
        return {}

    response = client.describe_cluster_versions(
        clusterVersions=sorted(versions), includeAll=True
    )
    return {
        item["clusterVersion"]: (
            item.get("versionStatus", "UNKNOWN"),
            as_date(item.get("endOfStandardSupportDate")),
            as_date(item.get("endOfExtendedSupportDate")),
        )
        for item in response.get("clusterVersions", [])
    }


def rds_lifecycle(engine: str, major: str, client, today: date) -> tuple:
    """(status, end_standard, end_extended) for one RDS/Aurora major version.

    RDS exposes no status field, so it is derived from the lifecycle windows.
    """
    response = client.describe_db_major_engine_versions(
        Engine=engine, MajorEngineVersion=major
    )
    entries = response.get("DBMajorEngineVersions", [])
    if not entries:
        return "UNKNOWN", None, None

    lifecycles = entries[0].get("SupportedEngineLifecycles", [])
    by_name = {item.get("LifecycleSupportName"): item for item in lifecycles}
    end_standard = as_date(
        (by_name.get(_RDS_STANDARD) or {}).get("LifecycleSupportEndDate")
    )
    end_extended = as_date(
        (by_name.get(_RDS_EXTENDED) or {}).get("LifecycleSupportEndDate")
    )

    if end_standard is None:
        return "UNKNOWN", None, end_extended
    if end_extended is not None and today > end_extended:
        return "UNSUPPORTED", end_standard, end_extended
    if today > end_standard:
        return "EXTENDED_SUPPORT", end_standard, end_extended
    return "STANDARD_SUPPORT", end_standard, end_extended
```

- [ ] **Step 4: Run test to verify it passes**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_lifecycle.py -v`
Expected: PASS (all green)

- [ ] **Step 5: Commit**

```bash
git add @bin/scripts/version_support/
git commit -m "feat(version-support): look up EKS and RDS support lifecycles"
```

---

## Task 9: Evaluate pins into findings, and the AWS-failure path

**Files:**
- Modify: `@bin/scripts/version_support/lifecycle.py`
- Modify: `@bin/scripts/version_support/tests/test_lifecycle.py`

- [ ] **Step 1: Write the failing test**

Append to `@bin/scripts/version_support/tests/test_lifecycle.py`:

```python
from version_support.discover import Pin
from version_support.lifecycle import LookupUnavailable, evaluate

EKS_PIN = Pin(
    kind="eks",
    engine=None,
    version="1.28",
    major_version="1.28",
    layer="apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
    active=True,
    source="cluster/variables.tf:9 (var.cluster_version)",
)


def test_evaluate_turns_pins_into_findings():
    eks = boto3.client("eks", region_name="us-east-1")
    rds = boto3.client("rds", region_name="us-east-1")
    with Stubber(eks) as stub:
        stub.add_response(
            "describe_cluster_versions",
            {
                "clusterVersions": [
                    {
                        "clusterVersion": "1.28",
                        "versionStatus": "EXTENDED_SUPPORT",
                        "endOfStandardSupportDate": datetime(2024, 11, 26),
                        "endOfExtendedSupportDate": datetime(2025, 11, 26),
                    }
                ]
            },
            {"clusterVersions": ["1.28"], "includeAll": True},
        )

        findings = evaluate([EKS_PIN], eks_client=eks, rds_client=rds, today=TODAY)

    assert len(findings) == 1
    assert findings[0].severity == "EXTENDED"
    assert findings[0].pin is EKS_PIN


def test_an_unresolvable_pin_is_unknown_without_calling_aws():
    unresolved = Pin(
        kind="eks",
        engine=None,
        version=None,
        major_version=None,
        layer="apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
        active=True,
        source="cluster/main.tf:5 (unresolved)",
    )
    eks = boto3.client("eks", region_name="us-east-1")
    rds = boto3.client("rds", region_name="us-east-1")

    # No Stubber responses queued: any AWS call would raise.
    with Stubber(eks), Stubber(rds):
        findings = evaluate([unresolved], eks_client=eks, rds_client=rds, today=TODAY)

    assert findings[0].severity == "UNKNOWN"


def test_an_aws_failure_raises_lookup_unavailable():
    eks = boto3.client("eks", region_name="us-east-1")
    rds = boto3.client("rds", region_name="us-east-1")
    with Stubber(eks) as stub:
        stub.add_client_error("describe_cluster_versions", service_error_code="AccessDenied")

        with pytest.raises(LookupUnavailable):
            evaluate([EKS_PIN], eks_client=eks, rds_client=rds, today=TODAY)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_lifecycle.py -k evaluate -v`
Expected: FAIL with `ImportError: cannot import name 'LookupUnavailable'`

- [ ] **Step 3: Write the implementation**

Add to the imports of `@bin/scripts/version_support/lifecycle.py`:

```python
from botocore.exceptions import BotoCoreError, ClientError
```

Then append:

```python
class LookupUnavailable(RuntimeError):
    """AWS could not be reached or refused the call.

    Raised rather than swallowed so callers must decide explicitly. A guardrail
    that silently reports 'all clear' when it could not run is worse than none.
    """


def evaluate(pins, *, eks_client, rds_client, today: date, lead_days: int = DEFAULT_LEAD_DAYS):
    """Turn pins into findings. Raises LookupUnavailable if AWS cannot be reached."""
    findings: list[Finding] = []

    resolvable = [pin for pin in pins if pin.major_version]
    eks_versions = {pin.major_version for pin in resolvable if pin.kind == "eks"}

    try:
        eks_map = eks_lifecycles(eks_versions, eks_client)
        rds_map = {}
        for pin in resolvable:
            if pin.kind != "rds":
                continue
            key = (pin.engine, pin.major_version)
            if key not in rds_map:
                rds_map[key] = rds_lifecycle(pin.engine, pin.major_version, rds_client, today)
    except (BotoCoreError, ClientError) as exc:
        raise LookupUnavailable(str(exc)) from exc

    for pin in pins:
        if not pin.major_version:
            findings.append(Finding(pin, "UNKNOWN", None, None, None, "UNKNOWN"))
            continue

        if pin.kind == "eks":
            status, end_standard, end_extended = eks_map.get(
                pin.major_version, ("UNKNOWN", None, None)
            )
        else:
            status, end_standard, end_extended = rds_map[(pin.engine, pin.major_version)]

        severity, days = classify(status, end_standard, today, lead_days)
        findings.append(
            Finding(pin, status, end_standard, end_extended, days, severity)
        )

    return findings
```

- [ ] **Step 4: Run test to verify it passes**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_lifecycle.py -v`
Expected: PASS (all green)

- [ ] **Step 5: Commit**

```bash
git add @bin/scripts/version_support/
git commit -m "feat(version-support): evaluate pins and surface AWS lookup failures"
```

---

## Task 10: Reporting

**Files:**
- Create: `@bin/scripts/version_support/report.py`
- Create: `@bin/scripts/version_support/tests/test_report.py`

- [ ] **Step 1: Write the failing test**

`@bin/scripts/version_support/tests/test_report.py`:

```python
from datetime import date

from version_support.discover import Pin
from version_support.lifecycle import Finding
from version_support.report import (
    annotations,
    blocking_findings,
    issue_body,
    markdown_table,
    slack_payload,
    slack_summary,
    terminal_table,
)

ACTIVE_EXTENDED = Finding(
    pin=Pin("eks", None, "1.28", "1.28", "apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
            True, "apps-devstg/.../variables.tf:9 (var.cluster_version)"),
    status="EXTENDED_SUPPORT",
    end_standard=date(2024, 11, 26),
    end_extended=date(2025, 11, 26),
    days_left=-647,
    severity="EXTENDED",
)
ACTIVE_SOON = Finding(
    pin=Pin("eks", None, "1.31", "1.31", "shared/us-east-1/k8s-eks/cluster",
            True, "shared/.../variables.tf:9 (var.cluster_version)"),
    status="STANDARD_SUPPORT",
    end_standard=date(2026, 11, 1),
    end_extended=date(2027, 11, 1),
    days_left=58,
    severity="SOON",
)
DISABLED_EXTENDED = Finding(
    pin=Pin("rds", "aurora-mysql", "5.7", "5.7", "apps-devstg/us-east-1/databases-aurora --",
            False, "apps-devstg/.../cluster_demoapps.tf:8"),
    status="EXTENDED_SUPPORT",
    end_standard=date(2024, 10, 31),
    end_extended=date(2027, 10, 31),
    days_left=-673,
    severity="EXTENDED",
)


def test_only_active_findings_block():
    result = blocking_findings([ACTIVE_EXTENDED, ACTIVE_SOON, DISABLED_EXTENDED])

    # A disabled layer costs nothing; gating on it would land the check red on
    # day one and keep it red.
    assert result == [ACTIVE_EXTENDED]


def test_annotations_error_on_blocking_and_warn_on_soon():
    lines = annotations([ACTIVE_EXTENDED, ACTIVE_SOON, DISABLED_EXTENDED])

    assert any(line.startswith("::error ") and "1.28" in line for line in lines)
    assert any(line.startswith("::warning ") and "1.31" in line for line in lines)
    assert not any("databases-aurora --" in line for line in lines)


def test_terminal_table_separates_latent_debt():
    text = terminal_table([ACTIVE_EXTENDED, DISABLED_EXTENDED])

    assert "apps-devstg/us-east-1/k8s-eks-demoapps/cluster" in text
    assert "would be in extended support if enabled" in text


def test_markdown_table_is_generated_with_a_date():
    text = markdown_table([ACTIVE_SOON], generated_on=date(2026, 9, 4))

    assert text.startswith("<!-- GENERATED")
    assert "2026-09-04" in text
    assert "| 1.31 |" in text


def test_slack_summary_counts_active_findings_only():
    text = slack_summary([ACTIVE_EXTENDED, ACTIVE_SOON, DISABLED_EXTENDED])

    assert "1 in extended support" in text
    assert "1 within the lead time" in text


def test_slack_payload_embeds_the_summary_and_run_url():
    payload = slack_payload(
        [ACTIVE_EXTENDED], repository="binbashar/le-tf-infra-aws", run_url="https://example/run/1"
    )
    section = payload["blocks"][1]

    assert "binbashar/le-tf-infra-aws" in section["text"]["text"]
    assert "1 in extended support" in section["text"]["text"]
    assert section["accessory"]["url"] == "https://example/run/1"


def test_issue_body_carries_the_dedupe_marker():
    body = issue_body([ACTIVE_SOON], generated_on=date(2026, 9, 4))

    assert "<!-- version-support-guardrail -->" in body
```

- [ ] **Step 2: Run test to verify it fails**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_report.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'version_support.report'`

- [ ] **Step 3: Write the implementation**

`@bin/scripts/version_support/report.py`:

```python
"""Render findings. Pure formatting - no I/O, no AWS, no filesystem."""

from __future__ import annotations

from datetime import date

from version_support.lifecycle import BLOCKING, Finding

ISSUE_MARKER = "<!-- version-support-guardrail -->"

_SEVERITY_ICON = {
    "OK": "🟢",
    "SOON": "🟡",
    "EXTENDED": "🔴",
    "UNSUPPORTED": "🔴",
    "UNKNOWN": "⚪",
}


def _name(finding: Finding) -> str:
    pin = finding.pin
    return f"{pin.engine or 'kubernetes'} {pin.version or '?'}"


def blocking_findings(findings: list[Finding]) -> list[Finding]:
    """Findings that must fail a PR: active layers only."""
    return [f for f in findings if f.pin.active and f.severity in BLOCKING]


def attention_findings(findings: list[Finding]) -> list[Finding]:
    """Active findings worth telling a human about."""
    return [
        f for f in findings if f.pin.active and f.severity in BLOCKING | {"SOON", "UNKNOWN"}
    ]


def annotations(findings: list[Finding]) -> list[str]:
    """GitHub Actions workflow-command lines. Disabled layers never annotate."""
    lines = []
    for finding in findings:
        if not finding.pin.active:
            continue
        if finding.severity in BLOCKING:
            level = "error"
        elif finding.severity in {"SOON", "UNKNOWN"}:
            level = "warning"
        else:
            continue
        # Strip the " (how)" suffix first, then the trailing ":line" -- splitting on
        # the first colon would truncate an absolute Windows path at its drive
        # letter. Not reachable today (_source builds paths with os.path.relpath,
        # which never emits one) but a wrong file= silently points a reviewer at the
        # wrong place, so this is cheap insurance.
        file_part = finding.pin.source.split(" (")[0].rsplit(":", 1)[0]
        lines.append(
            f"::{level} file={file_part}::{_name(finding)} in {finding.pin.layer} "
            f"is {finding.severity} (end of standard support: {finding.end_standard})"
        )
    return lines


def terminal_table(findings: list[Finding]) -> str:
    """Human-readable summary for the job log."""
    active = [f for f in findings if f.pin.active]
    disabled = [f for f in findings if not f.pin.active]
    lines = ["Active layers:"]
    if not active:
        lines.append("  (none)")
    for finding in sorted(active, key=lambda f: f.pin.layer):
        lines.append(
            f"  {_SEVERITY_ICON[finding.severity]} {finding.severity:12} "
            f"{_name(finding):28} {finding.pin.layer}"
        )
        lines.append(
            f"      end of standard support: {finding.end_standard}  "
            f"days left: {finding.days_left}  source: {finding.pin.source}"
        )

    if disabled:
        lines.append("")
        lines.append("Disabled layers (latent - never fails the check):")
        for finding in sorted(disabled, key=lambda f: f.pin.layer):
            if finding.severity == "UNSUPPORTED":
                note = "past extended support -- unsupported if enabled"
            elif finding.severity == "EXTENDED":
                note = "would be in extended support if enabled"
            else:
                note = finding.severity.lower()
            lines.append(f"  · {_name(finding):28} {finding.pin.layer} - {note}")
    return "\n".join(lines)


def markdown_table(findings: list[Finding], generated_on: date) -> str:
    """The committed status table."""
    header = [
        "<!-- GENERATED by @bin/scripts/version_support - do not edit by hand -->",
        "",
        "# Version support status",
        "",
        f"Generated **{generated_on.isoformat()}**. Regenerate with `make version-support-table`.",
        "",
        "| Layer | Kind | Engine | Version | Status | End of standard support | Days left |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    rows = []
    for finding in sorted(findings, key=lambda f: (not f.pin.active, f.pin.layer)):
        pin = finding.pin
        layer = pin.layer if pin.active else f"{pin.layer} _(disabled)_"
        rows.append(
            f"| {layer} | {pin.kind} | {pin.engine or 'kubernetes'} | {pin.version or '?'} "
            f"| {_SEVERITY_ICON[finding.severity]} {finding.severity} "
            f"| {finding.end_standard or '-'} | {finding.days_left if finding.days_left is not None else '-'} |"
        )
    return "\n".join(header + rows) + "\n"


def slack_summary(findings: list[Finding]) -> str:
    """One-paragraph mrkdwn summary for the weekly notification."""
    extended = [f for f in findings if f.pin.active and f.severity == "EXTENDED"]
    unsupported = [f for f in findings if f.pin.active and f.severity == "UNSUPPORTED"]
    soon = [f for f in findings if f.pin.active and f.severity == "SOON"]
    parts = []
    if unsupported:
        # Worse than extended support: past the paid window entirely. Only shown
        # when non-empty so the common case stays a two-part summary.
        parts.append(f"*{len(unsupported)} unsupported*")
    parts.extend([
        f"*{len(extended)} in extended support*" if extended else "0 in extended support",
        f"*{len(soon)} within the lead time*" if soon else "0 within the lead time",
    ])
    detail = "\n".join(
        f"• {_name(f)} — `{f.pin.layer}` — end of standard support {f.end_standard}"
        for f in unsupported + extended + soon
    )
    return " · ".join(parts) + ("\n" + detail if detail else "")


def slack_payload(findings: list[Finding], *, repository: str, run_url: str) -> dict:
    """Full incoming-webhook payload, written to a file the workflow posts verbatim.

    Building the whole payload here keeps multi-line summary text out of inline
    YAML, where embedded newlines would produce invalid JSON.
    """
    return {
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "Version support: action needed :hourglass_flowing_sand:",
                },
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": (
                        f"*Project*: {repository}\n"
                        f"{slack_summary(findings)}\n\n"
                        "Extended support bills at a multiple of the standard rate."
                    ),
                },
                "accessory": {
                    "type": "button",
                    "text": {
                        "type": "plain_text",
                        "text": ":arrow_forward: View run",
                        "emoji": True,
                    },
                    "url": run_url,
                    "action_id": "button-action",
                },
            },
        ]
    }


def issue_body(findings: list[Finding], generated_on: date) -> str:
    """Body for the recurring tracking issue, carrying the dedupe marker."""
    return "\n".join(
        [
            ISSUE_MARKER,
            "",
            "Versions approaching or past their end of standard support. "
            "Extended support bills at a multiple of the standard rate — "
            "the cheapest fix is the early one.",
            "",
            markdown_table(findings, generated_on),
            "",
            "_Opened and updated automatically by "
            "`.github/workflows/version-support.yml`._",
        ]
    )
```

- [ ] **Step 4: Run test to verify it passes**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_report.py -v`
Expected: PASS (all green)

- [ ] **Step 5: Commit**

```bash
git add @bin/scripts/version_support/
git commit -m "feat(version-support): render findings for humans and CI"
```

---

## Task 11: The CLI

**Files:**
- Create: `@bin/scripts/version_support/__main__.py`
- Create: `@bin/scripts/version_support/tests/test_main.py`

> **Second amendment.** The fix above was still too narrow. `AWS_DEFAULT_REGION=""` — an
> empty-but-present region, which `AWS_REGION: ${{ vars.UNDEFINED }}` produces verbatim in a
> workflow `env:` block — makes botocore raise a bare `ValueError` from endpoint construction,
> outside `BotoCoreError`/`ClientError`, reproducing the identical crash. The guard now catches
> broadly, scoped to just the two client constructions. Two further corrections landed with it:
> the `::warning::` was being written to **stderr**, which GitHub does not parse for workflow
> commands, so the promised "loud warning annotation" rendered as nothing; and `collect()` now
> short-circuits when `discover()` finds no pins, since there is nothing to ask AWS about.
>
> That short-circuit made the first draft of these tests **vacuous** — they used an empty
> `tmp_path` as `--root`, so no pins meant no client construction and they passed without ever
> exercising the path under test. They now point at the fixture tree. A test that passes for the
> wrong reason is the same false confidence this tool exists to prevent.
>
> **Amendment (found during execution).** The original `collect()` built the boto3 clients as
> *argument expressions* to `evaluate(...)`, so they were constructed **before** `evaluate`'s
> `try/except` could apply — and `main()` catches only `LookupUnavailable`. A construction-time
> failure such as `NoRegionError` (raised with no region resolvable, before any network call —
> exactly what a workflow step missing `aws-region` produces) therefore escaped uncaught and
> crashed **both** `pr` and `cron` with a traceback and exit 1, breaking the central "never block
> a merge on an AWS problem" guarantee that `lifecycle.py`'s own docstring states. Every test
> mocked `collect` wholesale, so none of them executed real client construction and the suite
> stayed green. The code above is corrected, and Step 1 now includes a test that does not mock
> `collect`.

- [ ] **Step 1: Write the failing test**

`@bin/scripts/version_support/tests/test_main.py`:

```python
import os
from datetime import date
from unittest import mock

import pytest

from version_support.__main__ import main
from version_support.discover import Pin
from version_support.lifecycle import Finding, LookupUnavailable

FIXTURE_TREE = os.path.join(os.path.dirname(__file__), "fixtures", "tree")

BLOCKING_FINDING = Finding(
    pin=Pin("eks", None, "1.28", "1.28", "apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
            True, "main.tf:5"),
    status="EXTENDED_SUPPORT",
    end_standard=date(2024, 11, 26),
    end_extended=date(2025, 11, 26),
    days_left=-647,
    severity="EXTENDED",
)
DISABLED_FINDING = Finding(
    pin=Pin("rds", "aurora-mysql", "5.7", "5.7", "apps-devstg/us-east-1/databases-aurora --",
            False, "cluster.tf:8"),
    status="EXTENDED_SUPPORT",
    end_standard=date(2024, 10, 31),
    end_extended=date(2027, 10, 31),
    days_left=-673,
    severity="EXTENDED",
)


def test_pr_mode_fails_on_an_active_blocking_finding():
    with mock.patch("version_support.__main__.collect", return_value=([BLOCKING_FINDING], [])):
        assert main(["--mode", "pr", "--root", FIXTURE_TREE]) == 1


def test_pr_mode_passes_when_only_disabled_layers_are_blocking():
    with mock.patch("version_support.__main__.collect", return_value=([DISABLED_FINDING], [])):
        assert main(["--mode", "pr", "--root", FIXTURE_TREE]) == 0


def test_cron_mode_never_fails():
    with mock.patch("version_support.__main__.collect", return_value=([BLOCKING_FINDING], [])):
        assert main(["--mode", "cron", "--root", FIXTURE_TREE]) == 0


def test_pr_mode_does_not_block_when_aws_is_unavailable():
    with mock.patch("version_support.__main__.collect", side_effect=LookupUnavailable("boom")):
        # Never block a merge on an AWS outage - but say so loudly.
        assert main(["--mode", "pr", "--root", FIXTURE_TREE]) == 0


def test_table_mode_writes_the_status_file(tmp_path):
    target = tmp_path / "status.md"
    with mock.patch("version_support.__main__.collect", return_value=([BLOCKING_FINDING], [])):
        assert main(["--mode", "table", "--root", FIXTURE_TREE, "--out", str(target)]) == 0

    assert "GENERATED" in target.read_text()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/test_main.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'version_support.__main__'`

- [ ] **Step 3: Write the implementation**

`@bin/scripts/version_support/__main__.py`:

```python
"""CLI for the version-support guardrail.

The only module that decides whether a run fails. Side effects that talk to Slack
or GitHub live in the workflow, not here.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import date, timezone, datetime

import boto3
from botocore.exceptions import BotoCoreError, ClientError

from version_support import discover as discover_module
from version_support import report as report_module
from version_support.lifecycle import DEFAULT_LEAD_DAYS, LookupUnavailable, evaluate


def collect(root: str, today: date, lead_days: int):
    """(findings, parse_errors) for the tree at `root`. Raises LookupUnavailable."""
    pins, errors = discover_module.discover(root)
    try:
        # Construction is inside the guard on purpose: boto3 can fail before any
        # network call -- NoRegionError when no region resolves, for one -- and
        # evaluate()'s own try/except cannot see that, because these expressions
        # are evaluated before its body runs. Left outside, a misconfigured
        # workflow step would crash the gate instead of degrading it.
        eks_client = boto3.client("eks")
        rds_client = boto3.client("rds")
    except Exception as exc:  # noqa: BLE001 - boto3 client construction can fail
        # outside botocore's documented exception hierarchy: an empty-but-present
        # region raises a bare ValueError from botocore.endpoint, reproduced with
        # AWS_DEFAULT_REGION="". Anything raised while building these two clients
        # means "AWS is not usable", never "our code has a bug".
        raise LookupUnavailable(str(exc)) from exc

    findings = evaluate(
        pins,
        eks_client=eks_client,
        rds_client=rds_client,
        today=today,
        lead_days=lead_days,
    )
    return findings, errors


def _write_github_output(key: str, value: str) -> None:
    path = os.environ.get("GITHUB_OUTPUT")
    if not path:
        return
    with open(path, "a", encoding="utf-8") as handle:
        handle.write(f"{key}={value}\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="version_support")
    parser.add_argument("--mode", choices=("pr", "cron", "table"), required=True)
    parser.add_argument("--root", default=".")
    parser.add_argument("--lead-days", type=int, default=DEFAULT_LEAD_DAYS)
    parser.add_argument("--out", default="docs/version-support/status.md")
    parser.add_argument("--summary-out", default=None)
    parser.add_argument("--issue-out", default=None)
    args = parser.parse_args(argv)

    today = datetime.now(timezone.utc).date()

    try:
        findings, errors = collect(args.root, today, args.lead_days)
    except LookupUnavailable as exc:
        # A check that silently passes when it could not run is worse than none.
        message = f"version-support: AWS lookup unavailable - the check did NOT run ({exc})"
        # stdout, not stderr: GitHub parses workflow commands from stdout only, so a
        # ::warning:: on stderr renders no annotation -- making this failure quiet,
        # the one outcome this handler exists to prevent.
        print(f"::warning::{message}")
        _write_github_output("ran", "false")
        return 0

    for error in errors:
        print(f"::warning::version-support: could not parse {error}")

    print(report_module.terminal_table(findings))
    _write_github_output("ran", "true")

    if args.mode == "table":
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write(report_module.markdown_table(findings, today))
        print(f"\nwrote {args.out}")
        return 0

    if args.mode == "pr":
        for line in report_module.annotations(findings):
            print(line)
        blocking = report_module.blocking_findings(findings)
        if blocking:
            print(
                f"\n{len(blocking)} active layer(s) pin a version in extended support."
            )
            return 1
        return 0

    # cron
    attention = report_module.attention_findings(findings)
    _write_github_output("has_findings", "true" if attention else "false")
    if args.summary_out:
        repository = os.environ.get("GITHUB_REPOSITORY", "")
        run_url = (
            f"{os.environ.get('GITHUB_SERVER_URL', 'https://github.com')}/"
            f"{repository}/actions/runs/{os.environ.get('GITHUB_RUN_ID', '')}"
        )
        payload = report_module.slack_payload(
            findings, repository=repository, run_url=run_url
        )
        with open(args.summary_out, "w", encoding="utf-8") as handle:
            json.dump(payload, handle)
    if args.issue_out:
        with open(args.issue_out, "w", encoding="utf-8") as handle:
            handle.write(report_module.issue_body(findings, today))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: Run test to verify it passes**

Run: `PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/ -v`
Expected: PASS (all green)

- [ ] **Step 5: Commit**

```bash
git add @bin/scripts/version_support/
git commit -m "feat(version-support): add the CLI with pr, cron and table modes"
```

---

## Task 12: Makefile targets

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Read the existing Makefile**

Run: `cat Makefile`
Note the existing `help`, `init-makefiles` and `infracost-breakdown` targets and the `## comment` help convention.

- [ ] **Step 2: Append the targets**

Add to `Makefile`, matching the existing `## description` convention so they appear in `make help`:

```makefile
# uv run, not a bare python3: the scanner needs python-hcl2 >= 8.1, while this repo's
# own .venv pins 7.3.1 for the Leverage CLI -- so resolving the interpreter from PATH
# breaks precisely for contributors who followed the setup guide. --with-requirements
# builds the environment on demand; there is no venv to create or activate.
.PHONY: version-support
version-support: ## Check EKS/RDS versions against AWS support lifecycles
	@PYTHONPATH=@bin/scripts uv run --quiet \
		--with-requirements @bin/scripts/version_support/requirements.txt \
		python -m version_support --mode pr --root .

.PHONY: version-support-table
version-support-table: ## Regenerate docs/version-support/status.md
	@PYTHONPATH=@bin/scripts uv run --quiet \
		--with-requirements @bin/scripts/version_support/requirements.txt \
		python -m version_support --mode table --root .
```

> **Amendment (found during execution).** The original targets called a bare `python3`. This
> repo's own `.venv` — the one `CLAUDE.md` tells contributors to create for the Leverage CLI —
> carries `python-hcl2 7.3.1`, which predates `hcl2/utils.py`, so `make version-support` died with
> `ModuleNotFoundError: No module named 'hcl2.utils'` for exactly the people who followed the
> setup guide. `uv` is already a documented prerequisite, and `uv run --with-requirements` builds
> a hermetic environment on demand.

- [ ] **Step 3: Verify the targets are listed**

Run: `make help | grep version-support`
Expected: both targets listed with their descriptions.

- [ ] **Step 4: Commit**

```bash
git add Makefile
git commit -m "feat(version-support): add make targets for the guardrail"
```

---

## Task 13: The workflow

**Files:**
- Create: `.github/workflows/version-support.yml`
- Modify: `atlantis.yaml`

> **Amendment (found during execution, after Task 3).** `atlantis.yaml` sets
> `autodiscover: mode: "enabled"` with `ignore_paths: [config/*]`. Atlantis treats *any*
> directory containing `.tf` files as a project, so the fixture tree added in Tasks 3, 4 and 6
> (`@bin/scripts/version_support/tests/fixtures/tree/**`) would be autodiscovered as real Terraform
> projects and planned on every PR — against module sources with no backend. Step 0 below fixes
> that. It must land before the branch is pushed in Task 15.

- [ ] **Step 0: Keep Atlantis out of the test fixtures**

In `atlantis.yaml`, extend `ignore_paths` so the scanner's fixture `.tf` files are never
mistaken for deployable layers:

```yaml
autodiscover:
  mode: "enabled"
  ignore_paths:
  - config/*
  # Test fixtures for @bin/scripts/version_support - .tf files on purpose, but not layers.
  - '@bin/scripts/**'
```

Verify the file still parses:

```bash
python3 -c "import yaml; yaml.safe_load(open('atlantis.yaml')); print('valid YAML')"
```


- [ ] **Step 1: Write the workflow**

`.github/workflows/version-support.yml`:

```yaml
name: Version support guardrail

# Prevention side of #1160. Reads the versions pinned in the tree - including
# disabled layers - and checks them against AWS support lifecycles.
# Detection from the billing side is the aws-finops plugin's job (#1159).
on:
  pull_request:
    paths:
      - '**/*.tf'
      - '@bin/scripts/version_support/**'
      - '.github/workflows/version-support.yml'
  # Tuesdays, deliberately off the Monday lint sweep so a red morning has one cause.
  schedule:
    - cron: '23 7 * * 2'
  workflow_dispatch:

permissions:
  contents: read
  issues: write        # the cron opens or updates the tracking issue

jobs:
  version-support:
    name: Version support
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          pip install -q -r @bin/scripts/version_support/requirements.txt pytest

      - name: Test the guardrail itself
        run: PYTHONPATH=@bin/scripts pytest ./@bin/scripts/version_support/tests/ -q

      # This repo is public, so a pull_request from a fork gets no secrets and
      # cannot assume the role. Detect that and skip the AWS phase rather than
      # failing a contributor's PR.
      - name: Check for AWS credentials
        id: creds
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        run: |
          if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
            echo "available=false" >> "$GITHUB_OUTPUT"
            echo "::notice::No AWS credentials (fork PR) - version-support did not run."
          else
            echo "available=true" >> "$GITHUB_OUTPUT"
          fi

      - name: Configure AWS credentials
        if: steps.creds.outputs.available == 'true'
        uses: aws-actions/configure-aws-credentials@v6
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
          role-to-assume: arn:aws:iam::${{ secrets.AWS_DEVSTG_ACCOUNT_ID }}:role/DeployMaster
          role-duration-seconds: 3600
          role-session-name: version-support

      - name: Run the PR gate
        id: gate
        if: github.event_name == 'pull_request' && steps.creds.outputs.available == 'true'
        run: PYTHONPATH=@bin/scripts python -m version_support --mode pr --root .

      - name: Run the weekly sweep
        id: sweep
        if: github.event_name != 'pull_request' && steps.creds.outputs.available == 'true'
        run: |
          PYTHONPATH=@bin/scripts python -m version_support --mode cron --root . \
            --summary-out /tmp/slack.json --issue-out /tmp/issue-body.md

      - name: Open or update the tracking issue
        if: steps.sweep.outputs.has_findings == 'true'
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          set -euo pipefail
          TITLE="chore(version-support): versions approaching end of standard support"
          EXISTING=$(gh issue list --state open --search "version-support-guardrail in:body" \
            --json number --jq '.[0].number // empty')
          if [ -n "${EXISTING}" ]; then
            gh issue edit "${EXISTING}" --body-file /tmp/issue-body.md
            echo "updated issue #${EXISTING}"
          else
            gh issue create --title "${TITLE}" --body-file /tmp/issue-body.md \
              --label cost-optimization --label enhancement
          fi

      # The scanner writes the whole payload, so the multi-line summary never has
      # to survive being interpolated into inline YAML as JSON.
      - name: Notify Slack
        if: steps.sweep.outputs.has_findings == 'true'
        uses: slackapi/slack-github-action@v2.0.0
        with:
          webhook: ${{ secrets.SLACK_DIRECT_WEBHOOK }}
          webhook-type: incoming-webhook
          payload-file-path: /tmp/slack.json
```

- [ ] **Step 2: Validate the YAML**

Run:

```bash
python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/version-support.yml')); print('valid YAML')"
```

Expected: `valid YAML`

- [ ] **Step 3: Commit**

```bash
# atlantis.yaml too -- Step 0 changed it, and leaving it uncommitted would drop the
# very fix that must land before this branch is pushed.
git add .github/workflows/version-support.yml atlantis.yaml
git commit -m "feat(version-support): add the PR gate and weekly sweep workflow"
```

---

## Task 14: Documentation, generated table, and cross-links

**Files:**
- Create: `docs/version-support/README.md`
- Create: `docs/version-support/status.md` (generated)
- Modify: `docs/finops/README.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Write the runbook**

`docs/version-support/README.md`:

````markdown
# Version support — EKS / RDS extended-support guardrail

AWS bills **extended support** for a Kubernetes version or an RDS/Aurora major engine
version past its end-of-standard-support date: EKS at `$0.60` per cluster-hour instead of
`$0.10` (**≈ +$365 per cluster per month**, charged *per cluster*), RDS/Aurora per vCPU-hour
on top of the instance price, increasing again in year three.

It is a **rate** change on unchanged infrastructure, so there is nothing to right-size and
neither Compute Optimizer nor Cost Optimization Hub reports it.

This guardrail is the **prevention** side. The **detection** side — catching the surcharge
on the bill via `USAGE_TYPE` — is the `aws-finops` plugin, see [`docs/finops/`](../finops/).

## What runs, and when

| Trigger | Behavior |
| --- | --- |
| PR touching `**/*.tf` | **Fails** if an *active* layer pins a version already in extended support; warns at ≤ 90 days |
| Weekly (Tuesdays 07:23 UTC) | Never fails. Posts to Slack and opens/updates one tracking issue |
| `workflow_dispatch` | Same as the weekly sweep |

Disabled layers (those whose directory ends in `--`) are scanned and reported as latent
debt but **never** fail the check — gating on five dormant database layers would land the
check red on day one. The moment a PR removes the `--` suffix, that layer counts as active
and the gate applies.

## Current status

See [`status.md`](status.md), regenerated with `make version-support-table`.

## Upgrade cadence

Kubernetes minor versions leave standard support roughly **14 months** after release; see
the [EKS release calendar](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html#kubernetes-release-calendar).

- **Plan the bump when the check first warns** (90 days out), not when it fails. The cheapest
  fix is the early one; the surcharge starts the day standard support ends.
- **EKS allows only one minor hop at a time.** Each bump is applied and verified before the
  next, so catching up from three versions behind is three sequential applies — budget for
  it rather than discovering it under time pressure. This constraint is also noted in
  `apps-devstg/us-east-1/k8s-eks-demoapps/cluster/variables.tf`.
- **Never land a substrate change and a version bump in the same apply.** The AL2 → AL2023
  migration was deliberately done while still on 1.31 for this reason.
- **RDS/Aurora major upgrades** are not one-hop-constrained but do require a maintenance
  window and a tested rollback; treat the 90-day warning as the trigger to schedule one.

## Running it locally

```bash
python3 -m venv .venv-version-support
./.venv-version-support/bin/pip install -r @bin/scripts/version_support/requirements.txt

# needs credentials for any account - the AWS calls are catalog lookups, not
# resource queries, so they return the same answer from anywhere
export AWS_PROFILE=bb-apps-devstg-devops
make version-support            # the PR gate
make version-support-table      # regenerate status.md
```

## IAM

Two read-only actions, and nothing else: `eks:DescribeClusterVersions` and
`rds:DescribeDBMajorEngineVersions`. Both describe AWS's *version catalog* rather than the
caller's resources, so any account works. CI assumes `DeployMaster` in `apps-devstg`, which
already grants `eks:*` and `rds:*` — **no IaC change was needed** for this guardrail.
````

- [ ] **Step 2: Generate the status table**

Run:

```bash
export AWS_PROFILE=bb-apps-devstg-devops    # or any valid profile
make version-support-table
cat docs/version-support/status.md
```

Expected: a table with 6 rows — 1 active EKS row and 5 disabled database rows marked `_(disabled)_`.

If no AWS credentials are available, skip this step and note that `status.md` will be
generated by the first successful workflow run.

- [ ] **Step 3: Cross-link from the FinOps runbook**

In `docs/finops/README.md`, find this exact text inside the bullet beginning
`- **A rate change is not usage growth.**`:

```markdown
  extended-support surcharge (issue #1160 tracks preventing that in the IaC). Report
  it as a monthly/annualised run-rate step, not a one-off anomaly.
```

and replace it with:

```markdown
  extended-support surcharge. Report it as a monthly/annualised run-rate step, not a
  one-off anomaly. The prevention side — a PR gate and weekly sweep that stop a version
  reaching that date unnoticed — is [`docs/version-support/`](../version-support/).
```

- [ ] **Step 4: Cross-link from CLAUDE.md**

In `CLAUDE.md`, immediately after the `### FinOps: analysing actual AWS spend` section
(before `### Advanced Operations`), add:

```markdown
### Version support guardrail

`make version-support` checks every Kubernetes and RDS/Aurora version **pinned in the tree**
— including disabled layers — against AWS's support lifecycles, so nothing crosses its
end-of-standard-support date into the extended-support surcharge unnoticed.

- A PR touching `**/*.tf` **fails** if an *active* layer pins a version already in extended
  support, and warns at ≤ 90 days. Disabled layers (directory ending `--`) are reported but
  never fail — removing the `--` makes the layer active and the gate applies.
- A weekly sweep posts to Slack and maintains one tracking issue; it never fails the repo.
- Needs only `eks:DescribeClusterVersions` + `rds:DescribeDBMajorEngineVersions` — catalog
  lookups, so any account's credentials work.
- Runbook and upgrade cadence: `docs/version-support/README.md`.

> Prevention side of the extended-support surcharge. The detection side — spotting it on the
> bill — is `aws-finops`, above.
```

- [ ] **Step 5: Run the full suite and the linter**

Run:

```bash
PYTHONPATH=@bin/scripts ./.venv-version-support/bin/pytest ./@bin/scripts/version_support/tests/ -v
pre-commit run --files $(git diff --name-only master...HEAD | tr '\n' ' ')
```

Expected: all tests pass; all pre-commit hooks pass.

- [ ] **Step 6: Commit**

```bash
git add docs/version-support/ docs/finops/README.md CLAUDE.md
git commit -m "docs(version-support): add the runbook, status table and cross-links"
```

---

## Task 15: End-to-end verification

- [ ] **Step 0: Cache `load_tfvars` per account**

Carried forward from Task 6's code review. `config/common.tfvars` is consulted for *every*
layer, not just every account, and this repo has **165 layers across 7 accounts** — so a single
malformed `common.tfvars` now emits up to 165 byte-identical lines in `errors` (measured, not
estimated). Caching the result per account inside one `discover()` call fixes the duplicate
reporting *and* stops re-opening and re-parsing the same two small files 165 times.

In `discover()`, hoist the tfvars lookup into a per-call cache keyed by account:

```python
def discover(root: str) -> tuple[list[Pin], list[str]]:
    """Walk `root` and return (pins, parse_errors)."""
    pins: list[Pin] = []
    errors: list[str] = []
    tfvars_cache: dict[str, dict] = {}

    for layer_dir in _layer_dirs(root):
        ...
        account = layer.replace("\\", "/").split("/")[0]
        if account not in tfvars_cache:
            # First layer in this account: parse once, report once. Without the
            # cache a broken common.tfvars is reported once per layer -- 165 times
            # in this repo.
            merged, tfvars_errors = load_tfvars(root, layer)
            tfvars_cache[account] = merged
            errors.extend(tfvars_errors)
        resolver = Resolver(docs, tfvars=tfvars_cache[account])
```

Then add a test asserting a broken `common.tfvars` is reported **once** across a multi-layer
tree, and confirm the real-tree scan still reports exactly 6 pins / 0 errors.


- [ ] **Step 1: Confirm the scanner sees the real tree correctly**

Run:

```bash
PYTHONPATH=@bin/scripts ./.venv-version-support/bin/python -c "
from version_support.discover import discover
pins, errors = discover('.')
print(f'{len(pins)} pins, {len(errors)} parse errors')
for p in sorted(pins, key=lambda p: p.layer):
    print(f'  {p.kind:4} {str(p.engine):20} {str(p.version):10} active={p.active!s:5} {p.source}')
"
```

Expected: `6 pins, 0 parse errors`, with `k8s-eks-demoapps/cluster` active and the five
`databases-*` layers inactive.

- [ ] **Step 2: Confirm the PR gate passes today**

Run: `make version-support`
Expected: exit 0. The one active cluster is on `1.34`, well inside standard support; the five
stale database pins appear under "Disabled layers (latent - never fails the check)".

- [ ] **Step 3: Confirm the gate would actually catch a regression**

Temporarily edit `apps-devstg/us-east-1/k8s-eks-demoapps/cluster/variables.tf` to
`default = "1.28"`, then:

Run: `make version-support`
Expected: exit **1**, with an `::error` annotation naming the layer.

Revert the edit:

```bash
git checkout apps-devstg/us-east-1/k8s-eks-demoapps/cluster/variables.tf
```

- [ ] **Step 4: Push and open the PR**

```bash
git push -u origin feat/version-support-guardrail-1160
```

Open the PR with the What / Why / References template, noting: the guardrail's own workflow
runs on it (the `@bin/scripts/version_support/**` path trigger), no IaC changes, and
`Refs #1160`.

- [ ] **Step 5: Confirm CI is green**

Run: `gh pr checks <number> --repo binbashar/le-tf-infra-aws`
Expected: `Version support`, `Test and Lint`, `test_leverage`, `Infracost` and
`GitGuardian Security Checks` all pass.
