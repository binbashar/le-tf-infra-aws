"""The CI runs native `tofu`, not `leverage tofu` (#1295). These tests fail when the
inputs the CI passes to OpenTofu stop matching what `leverage tofu` passes locally.

Leverage 3.1.0 (`leverage/modules/tf.py`, `tf_default_args` and `_init`) passes:
- `-var-file=` for every `*.tfvars` in the repository's `config/` and in the
  account's `config/`, in filesystem order;
- `-backend-config=<account>/config/backend.tfvars` to `init`.

Two kinds of drift are possible. The tree can change: someone adds a tfvars file that
Leverage would load and the CI would not, or sets one variable in two files so that the
unordered glob decides which value wins. The common file is checked through its committed
stand-in, `config/common.tfvars.example`; the CI's `TOFU_PLAN_COMMON_TFVARS` secret is not
visible here. Those are caught here on every run. The CLI
can change its rule: that is caught by `LeverageRuleTests`, which runs only where the
Leverage CLI is importable, and by `LEVERAGE_RULE_VERSION`, which says which release
this file was checked against.
"""

import importlib.util
import os
import re
import unittest
from pathlib import Path

from tofu_plan_ci import workflow

ROOT = Path(__file__).resolve().parents[4]
LEVERAGE_RULE_VERSION = "3.1.0"
# The CI writes config/common.tfvars from a secret; the committed stand-in is this one.
COMMON_EXAMPLE = ROOT / "config" / "common.tfvars.example"
# Names only: tofu fmt keeps top-level assignments in column 0 and nested keys indented.
TOP_LEVEL_ASSIGNMENT = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=")
HEREDOC_START = re.compile(r"<<-?([A-Za-z_][A-Za-z0-9_]*)\s*$")


def accounts() -> list[str]:
    return sorted(
        path.parent.name
        for path in ROOT.glob("*/config")
        if (path / "backend.tfvars").is_file()
    )


def top_level_names(path: Path) -> set[str]:
    names: set[str] = set()
    heredoc_end = None
    for line in path.read_text(encoding="utf-8").splitlines():
        # Heredoc bodies are string content: an `x = y` line inside one is not a variable.
        if heredoc_end:
            if line.strip() == heredoc_end:
                heredoc_end = None
            continue
        if match := TOP_LEVEL_ASSIGNMENT.match(line):
            names.add(match.group(1))
        if start := HEREDOC_START.search(line):
            heredoc_end = start.group(1)
    return names


class TreeMatchesTheCiTests(unittest.TestCase):
    def test_every_account_is_found(self):
        self.assertGreaterEqual(len(accounts()), 7)

    def test_the_ci_loads_every_tfvars_leverage_loads(self):
        committed_common = sorted(p.name for p in (ROOT / "config").glob("*.tfvars"))
        self.assertEqual(
            committed_common, [],
            "Leverage loads every config/*.tfvars; the CI writes only common.tfvars",
        )
        for account in accounts():
            with self.subTest(account=account):
                ci = {p.relative_to(ROOT) for p in workflow.layer_config_files(ROOT, f"{account}/global/x")}
                leverage = {Path("config/common.tfvars")} | {
                    p.relative_to(ROOT) for p in (ROOT / account / "config").glob("*.tfvars")
                }
                self.assertEqual(ci, leverage)

    def test_no_variable_is_set_in_two_files(self):
        # Leverage's glob has no defined order, so a variable set in two files would
        # get whichever value the filesystem lists last. Forbidding the overlap outright,
        # whatever the values, keeps the order irrelevant without parsing HCL values.
        for account in accounts():
            with self.subTest(account=account):
                files = [COMMON_EXAMPLE, *sorted((ROOT / account / "config").glob("*.tfvars"))]
                owners: dict[str, list[str]] = {}
                for path in files:
                    for name in top_level_names(path):
                        owners.setdefault(name, []).append(path.name)
                overlaps = {name: names for name, names in owners.items() if len(names) > 1}
                self.assertEqual(overlaps, {})

    def test_backend_config_is_the_account_backend_tfvars(self):
        *_, backend = workflow.layer_config_files(ROOT, "apps-devstg/global/cli-test-layer")
        self.assertEqual(backend, ROOT / "apps-devstg" / "config" / "backend.tfvars")


@unittest.skipUnless(importlib.util.find_spec("leverage"), "the Leverage CLI is not installed")
class LeverageRuleTests(unittest.TestCase):
    """Ask the installed CLI for its arguments and compare them with the CI's."""

    LAYER = "apps-devstg/global/cli-test-layer"

    def test_installed_cli_passes_the_same_var_files(self):
        import click
        import leverage
        from leverage import conf
        from leverage._internals import State
        from leverage.modules.tf import tf_default_args
        from leverage.path import PathsHandler

        # The CI always writes config/common.tfvars; a checkout usually lacks it, so
        # create a stand-in to see whether the CLI still loads it. An operator's own
        # file is left alone, and only a file this test created is removed.
        common = ROOT / "config" / "common.tfvars"
        created = not common.exists()
        if created:
            common.write_text("# test_leverage_parity stand-in\n", encoding="utf-8")
        previous = Path.cwd()
        try:
            os.chdir(ROOT / self.LAYER)
            state = State()
            state.paths = PathsHandler(conf.load())
            with click.Context(click.Command("parity"), obj=state):
                arguments = tf_default_args()
        finally:
            os.chdir(previous)
            if created:
                common.unlink()

        loaded = sorted(Path(argument.removeprefix("-var-file=")).resolve() for argument in arguments)
        ci = sorted(path.resolve() for path in workflow.layer_config_files(ROOT, self.LAYER))
        self.assertEqual(
            loaded, ci,
            f"Leverage {leverage.__version__} loads different tfvars than the CI; "
            f"this test was written against {LEVERAGE_RULE_VERSION}",
        )


if __name__ == "__main__":
    unittest.main()
