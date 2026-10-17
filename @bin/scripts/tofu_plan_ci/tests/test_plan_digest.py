import copy
import unittest

from tofu_plan_ci.plan_digest import canonical_changes, digests_match, plan_digest

KEY = "k" * 32


class PlanDigestTests(unittest.TestCase):
    def plan(self):
        return {
            "format_version": "1.0",
            "resource_drift": [
                {"address": "aws_s3_bucket.drifted", "change": {"actions": ["update"], "before": {"a": 1}, "after": {"a": 2}}}
            ],
            "resource_changes": [
                {
                    "address": "aws_iam_role.b",
                    "change": {"actions": ["create"], "before": None, "after": {"name": "b"}, "after_unknown": {"arn": True}},
                },
                {
                    "address": "aws_iam_role.a",
                    "change": {"actions": ["update"], "before": {"secret": "old"}, "after": {"secret": "new"}},
                },
                {"address": "aws_iam_role.unchanged", "change": {"actions": ["no-op"], "before": {}, "after": {}}},
            ],
            "output_changes": {"arn": {"actions": ["update"], "before": "x", "after": "y"}},
        }

    def test_format_and_determinism(self):
        digest = plan_digest(self.plan(), KEY)
        self.assertRegex(digest, r"\Ahmac-sha256:v1:[0-9a-f]{64}\Z")
        self.assertEqual(digest, plan_digest(self.plan(), KEY))

    def test_order_of_resources_and_keys_does_not_matter(self):
        reordered = self.plan()
        reordered["resource_changes"].reverse()
        reordered["resource_changes"][0]["change"] = dict(
            reversed(list(reordered["resource_changes"][0]["change"].items()))
        )
        self.assertEqual(plan_digest(self.plan(), KEY), plan_digest(reordered, KEY))

    def test_a_changed_value_changes_the_digest(self):
        changed = self.plan()
        changed["resource_changes"][1]["change"]["after"]["secret"] = "other"
        self.assertNotEqual(plan_digest(self.plan(), KEY), plan_digest(changed, KEY))

    def test_a_changed_action_or_output_changes_the_digest(self):
        actions = self.plan()
        actions["resource_changes"][1]["change"]["actions"] = ["delete", "create"]
        output = self.plan()
        output["output_changes"]["arn"]["after"] = "z"
        for other in (actions, output):
            self.assertNotEqual(plan_digest(self.plan(), KEY), plan_digest(other, KEY))

    def test_drift_and_no_ops_are_not_part_of_the_apply(self):
        quiet = self.plan()
        quiet["resource_drift"] = []
        quiet["resource_changes"] = quiet["resource_changes"][:2]
        quiet["prior_state"] = {"values": {"anything": True}}
        self.assertEqual(plan_digest(self.plan(), KEY), plan_digest(quiet, KEY))
        addresses = [r["address"] for r in canonical_changes(self.plan())["resource_changes"]]
        self.assertEqual(addresses, ["aws_iam_role.a", "aws_iam_role.b"])

    def test_the_key_matters_and_must_be_long(self):
        self.assertNotEqual(plan_digest(self.plan(), KEY), plan_digest(self.plan(), "j" * 32))
        with self.assertRaises(ValueError):
            plan_digest(self.plan(), "short")

    def test_digest_does_not_contain_values(self):
        self.assertNotIn("new", plan_digest(self.plan(), KEY))

    def test_match_requires_two_well_formed_equal_digests(self):
        digest = plan_digest(self.plan(), KEY)
        self.assertTrue(digests_match(digest, copy.copy(digest)))
        self.assertFalse(digests_match(digest, plan_digest(self.plan(), "j" * 32)))
        self.assertFalse(digests_match("", ""))
        self.assertFalse(digests_match("hmac-sha256:v1:zz", "hmac-sha256:v1:zz"))


if __name__ == "__main__":
    unittest.main()
