import unittest
from pathlib import Path

from infracost_ci import config, scope
from tofu_plan_ci.discover import account_names, working_tree_roots

REPO_ROOT = Path(__file__).resolve().parents[4]


class ConfigTests(unittest.TestCase):
    def test_var_files_resolve_from_the_layer_at_any_depth(self):
        self.assertEqual(
            config.var_files("shared/us-east-1/base-network"),
            [
                "../../../config/common.tfvars",
                "../../config/account.tfvars",
                "../../config/backend.tfvars",
            ],
        )
        self.assertEqual(
            config.var_files("shared/global/base-dns/binbash.co"),
            [
                "../../../../config/common.tfvars",
                "../../../config/account.tfvars",
                "../../../config/backend.tfvars",
            ],
        )

    def test_v01_schema_uses_flat_var_files(self):
        text = config.render(["b/x/y", "a/x/y"], schema="0.1")
        self.assertIn('version: "0.1"', text)
        self.assertIn("    terraform_var_files:\n", text)
        self.assertLess(text.index('"a/x/y"'), text.index('"b/x/y"'))

    def test_v03_schema_nests_var_files(self):
        text = config.render(["a/x/y"], schema="0.3")
        self.assertIn('version: "0.3"', text)
        self.assertIn("    terraform:\n      var_files:\n        - ", text)

    def test_empty_layer_set_is_an_empty_project_list(self):
        self.assertTrue(config.render([]).endswith("projects: []\n"))

    def test_paths_with_spaces_are_quoted(self):
        self.assertIn('- path: "a/x/odd name"', config.render(["a/x/odd name"]))

    def test_rejects_unknown_schema(self):
        with self.assertRaises(ValueError):
            config.render(["a/x/y"], schema="9")


class ScopeTests(unittest.TestCase):
    def setUp(self):
        self.active = {
            "apps-devstg/us-east-1/base-network",
            "apps-devstg/us-east-1/elasticache-redis",
            "shared/us-east-1/base-network",
            "shared/us-east-1/tools-vpn-server",
        }
        self.disabled = {"shared/us-east-1/tools-vault --", "data-science/us-east-1/airflow-- "}
        self.accounts = {"apps-devstg", "shared", "data-science"}

    def run_scope(self, paths, *, base_active=None, active=None):
        return scope.scope(
            changed_paths=paths,
            active_roots=self.active if active is None else active,
            disabled_roots=self.disabled,
            base_active_roots=self.active if base_active is None else base_active,
            base_disabled_roots=self.disabled,
            accounts=self.accounts,
        )

    def test_selects_only_the_changed_layer(self):
        result = self.run_scope(["apps-devstg/us-east-1/elasticache-redis/main.tf"])
        self.assertEqual(result["head_layers"], ["apps-devstg/us-east-1/elasticache-redis"])
        self.assertEqual(result["base_layers"], result["head_layers"])

    def test_docs_only_change_selects_nothing(self):
        result = self.run_scope(["README.md", "docs/finops/README.md"])
        self.assertEqual((result["head_layers"], result["base_layers"]), ([], []))

    def test_disabled_layer_is_skipped_not_estimated(self):
        result = self.run_scope(["shared/us-east-1/tools-vault --/main.tf"])
        self.assertEqual(result["head_layers"], [])
        self.assertEqual(result["skipped"][0]["path"], "shared/us-east-1/tools-vault --")

    def test_project_config_change_expands_to_every_active_layer(self):
        result = self.run_scope(["config/common-variables.tf"])
        self.assertEqual(result["head_layers"], sorted(self.active))
        self.assertTrue(result["scope_reasons"])

    def test_account_config_change_expands_to_that_account(self):
        result = self.run_scope(["shared/config/backend.tfvars"])
        self.assertEqual(
            result["head_layers"],
            ["shared/us-east-1/base-network", "shared/us-east-1/tools-vpn-server"],
        )

    def test_no_layer_cap(self):
        many = {f"shared/us-east-1/layer-{i}" for i in range(50)}
        result = self.run_scope(["config/common.tfvars.example"], active=many, base_active=many)
        self.assertEqual(len(result["head_layers"]), 50)

    def test_deleted_layer_is_estimated_on_the_base_side_only(self):
        gone = "apps-devstg/us-east-1/elasticache-redis"
        result = self.run_scope([f"{gone}/main.tf"], active=self.active - {gone})
        self.assertEqual(result["head_layers"], [])
        self.assertEqual(result["base_layers"], [gone])
        self.assertEqual(result["deleted_layers"], [gone])
        self.assertEqual(result["skipped"], [])

    def test_new_layer_is_estimated_on_the_head_side_only(self):
        new = "apps-devstg/us-east-1/elasticache-redis"
        result = self.run_scope([f"{new}/main.tf"], base_active=self.active - {new})
        self.assertEqual(result["head_layers"], [new])
        self.assertEqual(result["base_layers"], [])
        self.assertEqual(result["new_layers"], [new])

    def test_check_changes_estimate_the_smoke_layer(self):
        result = self.run_scope([".github/workflows/infracost.yml"])
        self.assertEqual(result["head_layers"], list(scope.SMOKE_LAYERS))
        self.assertIn("Infracost check changed", result["scope_reasons"][0])

    def test_plan_ci_self_test_does_not_leak_into_scope(self):
        result = self.run_scope([".github/workflows/tofu-plan.yml"])
        self.assertEqual((result["head_layers"], result["scope_reasons"]), ([], []))

    def test_markdown_names_the_no_op(self):
        self.assertIn("did not run", scope.render_markdown(self.run_scope(["README.md"])))


class RepositoryTests(unittest.TestCase):
    def test_smoke_layers_are_active_in_this_repository(self):
        active, _ = working_tree_roots(REPO_ROOT, account_names(REPO_ROOT))
        for layer in scope.SMOKE_LAYERS:
            self.assertIn(layer, active)

    def test_every_generated_var_file_exists(self):
        active, _ = working_tree_roots(REPO_ROOT, account_names(REPO_ROOT))
        for layer in active:
            for relative in config.var_files(layer)[1:]:
                self.assertTrue((REPO_ROOT / layer / relative).resolve().is_file(), (layer, relative))


if __name__ == "__main__":
    unittest.main()
