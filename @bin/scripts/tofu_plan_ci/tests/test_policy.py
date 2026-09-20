import tempfile
import unittest
from pathlib import Path

from tofu_plan_ci.policy import changed_hcl_documents, live_plan_blockers


class LivePlanPolicyTests(unittest.TestCase):
    def test_regular_resource_change_is_eligible(self):
        blockers = live_plan_blockers(
            ["apps-devstg/global/cli-test-layer/roles.tf"],
            "@@ -1 +1 @@\n-  description = \"old\"\n+  description = \"new\"\n",
        )
        self.assertEqual(blockers, [])

    def test_control_plane_and_lock_changes_are_suppressed(self):
        blockers = live_plan_blockers(
            [
                ".github/workflows/tofu-plan-poc.yml",
                "apps-devstg/global/cli-test-layer/.terraform.lock.hcl",
            ]
        )
        self.assertTrue(any("control-plane" in reason for reason in blockers))
        self.assertTrue(any("lock file" in reason for reason in blockers))

    def test_config_and_module_source_changes_are_suppressed(self):
        blockers = live_plan_blockers(
            ["apps-devstg/global/cli-test-layer/config.tf"],
            '@@ -1 +1 @@\n-  source = "old/module"\n+  source = "new/module"\n',
        )
        self.assertTrue(any("execution configuration" in reason for reason in blockers))
        self.assertTrue(any("source changed" in reason for reason in blockers))

    def test_external_program_and_provisioner_are_suppressed(self):
        blockers = live_plan_blockers(
            ["apps-devstg/global/cli-test-layer/main.tf"],
            '+data "external" "unsafe" {}\n+provisioner "local-exec" {}\n',
        )
        self.assertTrue(any("external data" in reason for reason in blockers))
        self.assertTrue(any("provisioner" in reason for reason in blockers))

    def test_edit_inside_an_existing_provisioner_is_suppressed(self):
        blockers = live_plan_blockers(
            ["apps-devstg/global/layer/main.tf"],
            '@@ -3 +3 @@\n- command = "safe"\n+ command = "unsafe"\n',
            {
                "apps-devstg/global/layer/main.tf": (
                    'resource "null_resource" "example" {\n'
                    '  provisioner "local-exec" { command = "unsafe" }\n'
                    "}\n"
                )
            },
        )
        self.assertTrue(any("provisioner" in reason for reason in blockers))
        self.assertTrue(any("compatibility resource" in reason for reason in blockers))

    def test_changed_hcl_symlink_is_suppressed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "payload.txt"
            target.write_text('module "unsafe" { source = "example.invalid/module" }')
            link = root / "main.tf"
            link.symlink_to(target)
            documents = changed_hcl_documents(root, ["main.tf"])
            blockers = live_plan_blockers(
                ["main.tf"], hcl_documents=documents
            )
            self.assertTrue(any("symlink" in reason for reason in blockers))


if __name__ == "__main__":
    unittest.main()
