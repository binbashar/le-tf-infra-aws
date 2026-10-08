import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tofu_plan_ci.discover import (
    discover_from_paths,
    git_changed_paths,
    manual_discovery,
    working_tree_roots,
)


class DiscoverTests(unittest.TestCase):
    def setUp(self):
        self.active = {
            "apps-devstg/global/cli-test-layer",
            "apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
            "security/us-east-1/security-audit",
        }
        self.disabled = {
            "apps-devstg/us-east-1/tools-apigw-apps-proxy --",
            "data-science/us-east-1/airflow-- ",
        }
        self.accounts = {"apps-devstg", "security", "data-science"}

    def discover(self, paths, **kwargs):
        return discover_from_paths(
            changed_paths=paths,
            active_roots=self.active,
            disabled_roots=self.disabled,
            base_active_roots=self.active,
            base_disabled_roots=self.disabled,
            accounts=self.accounts,
            max_layers=kwargs.pop("max_layers", 10),
            **kwargs,
        )

    def test_finds_nested_layer_at_its_real_depth(self):
        result = self.discover(
            ["apps-devstg/us-east-1/k8s-eks-demoapps/cluster/main.tf"]
        )
        self.assertEqual(
            result["layers"],
            ["apps-devstg/us-east-1/k8s-eks-demoapps/cluster"],
        )

    def test_disabled_layer_with_spaces_is_reported_not_selected(self):
        result = self.discover(
            ["apps-devstg/us-east-1/tools-apigw-apps-proxy --/config.tf"]
        )
        self.assertEqual(result["layers"], [])
        self.assertIn("disabled layer", result["skipped"][0]["reason"])

    def test_account_config_expands_only_that_account(self):
        result = self.discover(["apps-devstg/config/account.tfvars"])
        self.assertEqual(
            result["layers"],
            [
                "apps-devstg/global/cli-test-layer",
                "apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
            ],
        )

    def test_project_config_expansion_never_truncates_silently(self):
        result = self.discover(["config/common-variables.tf"], max_layers=2)
        self.assertEqual(result["layers"], [])
        self.assertIn("above the POC safety limit", result["blocked_reason"])
        self.assertEqual(len(result["candidate_layers"]), 3)

    def test_allowlist_keeps_poc_scope_explicit(self):
        result = self.discover(
            [
                "apps-devstg/global/cli-test-layer/roles.tf",
                "security/us-east-1/security-audit/config.tf",
            ],
            allow_layers={"apps-devstg/global/cli-test-layer"},
        )
        self.assertEqual(result["layers"], ["apps-devstg/global/cli-test-layer"])
        self.assertEqual(result["skipped"][0]["path"], "security/us-east-1/security-audit")

    def test_poc_implementation_change_self_tests_the_allowlisted_layer(self):
        result = self.discover(
            [".github/workflows/tofu-plan-poc.yml"],
            allow_layers={"apps-devstg/global/cli-test-layer"},
        )
        self.assertEqual(result["layers"], ["apps-devstg/global/cli-test-layer"])
        self.assertIn("POC implementation changed", result["scope_reasons"][0])

    def test_deleted_layer_is_not_mistaken_for_a_parent(self):
        result = discover_from_paths(
            changed_paths=["security/us-east-1/removed/config.tf"],
            active_roots=self.active,
            disabled_roots=self.disabled,
            base_active_roots=self.active | {"security/us-east-1/removed"},
            base_disabled_roots=self.disabled,
            accounts=self.accounts,
        )
        self.assertEqual(result["layers"], [])
        self.assertIn("no longer exists", result["skipped"][0]["reason"])
        self.assertIn("cannot be planned", result["blocked_reason"])

    def test_manual_dispatch_outside_allowlist_is_blocked(self):
        result = manual_discovery(
            layer="security/us-east-1/security-audit",
            active_roots=self.active,
            disabled_roots=self.disabled,
            allow_layers={"apps-devstg/global/cli-test-layer"},
        )
        self.assertEqual(result["layers"], [])
        self.assertIn("outside the POC allowlist", result["blocked_reason"])

    def test_manual_dispatch_rejects_path_traversal(self):
        with self.assertRaises(ValueError):
            manual_discovery(
                layer="../security/us-east-1/security-audit",
                active_roots=self.active,
                disabled_roots=self.disabled,
                allow_layers=None,
            )

    def test_cached_provider_modules_are_not_discovered_as_layers(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "apps-devstg/config").mkdir(parents=True)
            (root / "apps-devstg/config/account.tfvars").touch()
            (root / "apps-devstg/us-east-1/real").mkdir(parents=True)
            (root / "apps-devstg/us-east-1/real/config.tf").touch()
            cached = root / "apps-devstg/us-east-1/real/.terraform/modules/vendor"
            cached.mkdir(parents=True)
            (cached / "config.tf").touch()
            active, _ = working_tree_roots(root, {"apps-devstg"})
            self.assertEqual(active, {"apps-devstg/us-east-1/real"})

    def test_git_diff_uses_the_merge_base_for_a_branch_behind_base(self):
        with patch("tofu_plan_ci.discover.subprocess.run") as run:
            run.return_value.stdout = b"main.tf\0"
            self.assertEqual(
                git_changed_paths(Path("/repo"), "base-sha", "head-sha"),
                ["main.tf"],
            )
        self.assertIn("base-sha...head-sha", run.call_args.args[0])


if __name__ == "__main__":
    unittest.main()
