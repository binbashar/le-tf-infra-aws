import json
import tempfile
import unittest
from pathlib import Path

from tofu_plan_ci.plan_identity import (
    backend_state_key,
    parse_roles,
    read_tfvar,
    resolve,
    session_policy,
)

ROLES = json.dumps(
    {
        "management": {
            "role_arn": "arn:aws:iam::111111111111:role/GitHubActionsOpenTofuPlan",
            "account_id": "111111111111",
        }
    }
)


class PlanIdentityTests(unittest.TestCase):
    def test_parse_roles_rejects_a_role_outside_its_account(self):
        value = json.dumps(
            {
                "management": {
                    "role_arn": "arn:aws:iam::222222222222:role/GitHubActionsOpenTofuPlan",
                    "account_id": "111111111111",
                }
            }
        )
        with self.assertRaisesRegex(ValueError, "not in its account_id"):
            parse_roles(value)

    def test_parse_roles_rejects_extra_or_malformed_fields(self):
        for value in (
            "not json",
            "{}",
            json.dumps({"management": {"role_arn": "x", "account_id": "111111111111"}}),
            json.dumps({"management": {"role_arn": "x", "account_id": "1", "extra": 1}}),
        ):
            with self.assertRaises(ValueError, msg=value):
                parse_roles(value)

    def test_backend_state_key_requires_exactly_one_safe_key(self):
        self.assertEqual(
            backend_state_key('terraform {\n  backend "s3" {\n    key = "management/sso/terraform.tfstate"\n  }\n}\n'),
            "management/sso/terraform.tfstate",
        )
        for text in (
            'terraform {\n  backend "s3" {}\n}\n',
            'terraform {\n  backend "s3" {\n    key = "../other/terraform.tfstate"\n  }\n}\n',
            'locals {\n  key = "management/sso/terraform.tfstate"\n}\n',
        ):
            with self.assertRaises(ValueError, msg=text):
                backend_state_key(text)

    def test_read_tfvar_rejects_values_that_could_widen_an_arn(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "backend.tfvars"
            path.write_text('bucket = "bb-management-terraform-backend"\ndynamodb_table = "*"\n')
            self.assertEqual(read_tfvar(path, "bucket"), "bb-management-terraform-backend")
            with self.assertRaisesRegex(ValueError, "unsafe dynamodb_table"):
                read_tfvar(path, "dynamodb_table")

    def test_session_policy_narrows_only_the_state_backend(self):
        document = session_policy(
            bucket="state-bucket",
            table="lock-table",
            region="us-east-1",
            account_id="111111111111",
            state_key="management/sso/terraform.tfstate",
        )
        self.assertLessEqual(len(document), 2048)
        statements = {item["Sid"]: item for item in json.loads(document)["Statement"]}
        self.assertEqual(
            statements["ReadOwnState"]["Resource"],
            "arn:aws:s3:::state-bucket/management/sso/terraform.tfstate",
        )
        self.assertIn("s3:GetObject", statements["RolePermissions"]["NotAction"])
        self.assertEqual(
            statements["ObjectsOutsideStateBucket"]["NotResource"],
            ["arn:aws:s3:::state-bucket", "arn:aws:s3:::state-bucket/*"],
        )
        self.assertEqual(
            statements["OwnLockItems"]["Condition"]["ForAllValues:StringEquals"][
                "dynamodb:LeadingKeys"
            ],
            [
                "state-bucket/management/sso/terraform.tfstate",
                "state-bucket/management/sso/terraform.tfstate-md5",
            ],
        )
        self.assertFalse(
            any(item["Effect"] == "Allow" and item.get("Resource") == "*"
                and "Action" in item for item in statements.values())
        )

    def test_apply_session_policy_writes_only_its_own_state(self):
        document = session_policy(
            bucket="state-bucket",
            table="lock-table",
            region="us-east-1",
            account_id="111111111111",
            state_key="apps-devstg/cli-test-layer/terraform.tfstate",
            write_state=True,
        )
        self.assertLessEqual(len(document), 2048)
        statements = {item["Sid"]: item for item in json.loads(document)["Statement"]}
        self.assertEqual(statements["ReadWriteOwnState"]["Action"], ["s3:GetObject", "s3:PutObject"])
        self.assertEqual(
            statements["ReadWriteOwnState"]["Resource"],
            "arn:aws:s3:::state-bucket/apps-devstg/cli-test-layer/terraform.tfstate",
        )
        self.assertIn("s3:PutObject", statements["RolePermissions"]["NotAction"])
        self.assertEqual(
            statements["ObjectsOutsideStateBucket"]["NotResource"],
            ["arn:aws:s3:::state-bucket", "arn:aws:s3:::state-bucket/*"],
        )
        self.assertEqual(statements["OwnLockItems"]["Action"],
                         ["dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:PutItem"])

    def test_resolve_names_the_roles_variable_and_kind(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ValueError, "TOFU_APPLY_ROLES has no apply role"):
                resolve(Path(directory), "apps-devstg/global/cli-test-layer", ROLES,
                        roles_name="TOFU_APPLY_ROLES", write_state=True)

    def test_resolve_uses_the_layer_account_and_backend(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "management/config").mkdir(parents=True)
            (root / "management/global/sso").mkdir(parents=True)
            (root / "management/config/backend.tfvars").write_text(
                'bucket = "mgmt-state"\nregion = "us-east-1"\ndynamodb_table = "mgmt-lock"\n'
            )
            (root / "management/global/sso/config.tf").write_text(
                'terraform {\n  backend "s3" {\n    key = "management/sso/terraform.tfstate"\n  }\n}\n'
            )
            resolved = resolve(root, "management/global/sso", ROLES)
            self.assertEqual(resolved["account_id"], "111111111111")
            self.assertIn("mgmt-state/management/sso/terraform.tfstate", resolved["session_policy"])
            with self.assertRaisesRegex(ValueError, "no plan role for account 'apps-devstg'"):
                resolve(root, "apps-devstg/global/cli-test-layer", ROLES)


if __name__ == "__main__":
    unittest.main()
