import json
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

from tofu_plan_ci.bedrock_analysis import (
    inference_config,
    invoke_bedrock,
    llm_payload,
    load_reviews,
    parse_model_tool_use,
    render_markdown,
    validate_analysis_layers,
)


class BedrockAnalysisTests(unittest.TestCase):
    def analysis(self):
        return {
            "overall_risk": "high",
            "executive_summary": ["One role is replaced."],
            "layers": [
                {
                    "layer": "apps-devstg/global/cli-test-layer",
                    "summary": ["The IAM role changes."],
                    "risks": ["Replacement can interrupt assumers."],
                    "reviewer_questions": ["Is replacement expected?"],
                }
            ],
            "limitations": ["Values were removed."],
        }

    def test_parses_forced_tool_response(self):
        response = {
            "output": {
                "message": {
                    "content": [
                        {
                            "toolUse": {
                                "name": "review_sanitized_tofu_plan",
                                "input": self.analysis(),
                            }
                        }
                    ]
                }
            }
        }
        self.assertEqual(parse_model_tool_use(response)["overall_risk"], "high")

    def test_unreviewed_models_are_rejected_before_invocation(self):
        for model_id in ("amazon.nova-pro-v1:0", "us.anthropic.claude-sonnet-4-6"):
            with self.subTest(model_id=model_id), self.assertRaises(ValueError):
                invoke_bedrock(
                    payload={"layers": []},
                    model_id=model_id,
                    region="us-east-1",
                    request_metadata={"run-id": "test"},
                )

    def test_claude_5_requests_omit_temperature(self):
        self.assertEqual(inference_config("us.anthropic.claude-haiku-5-5"), {"maxTokens": 2400})
        self.assertEqual(
            inference_config("amazon.nova-lite-v1:0"), {"maxTokens": 2400, "temperature": 0}
        )

    def test_haiku_invocation_forces_the_tool_without_thinking(self):
        client = Mock()
        client.converse.return_value = {
            "output": {
                "message": {
                    "content": [
                        {
                            "toolUse": {
                                "name": "review_sanitized_tofu_plan",
                                "input": self.analysis(),
                            }
                        }
                    ]
                }
            }
        }
        boto3 = types.ModuleType("boto3")
        boto3.client = Mock(return_value=client)
        with patch.dict(sys.modules, {"boto3": boto3}):
            invoke_bedrock(
                payload={"layers": []},
                model_id="us.anthropic.claude-haiku-5-5",
                region="us-east-1",
                request_metadata={"run-id": "test"},
            )
        request = client.converse.call_args.kwargs
        self.assertNotIn("outputConfig", request)
        self.assertEqual(
            request["toolConfig"]["toolChoice"]["tool"]["name"],
            "review_sanitized_tofu_plan",
        )
        self.assertEqual(
            request["additionalModelRequestFields"], {"thinking": {"type": "disabled"}}
        )
        self.assertNotIn("temperature", request["inferenceConfig"])

    def test_nova_invocation_forces_the_review_tool(self):
        client = Mock()
        client.converse.return_value = {
            "output": {
                "message": {
                    "content": [
                        {
                            "toolUse": {
                                "name": "review_sanitized_tofu_plan",
                                "input": self.analysis(),
                            }
                        }
                    ]
                }
            }
        }
        boto3 = types.ModuleType("boto3")
        boto3.client = Mock(return_value=client)
        with patch.dict(sys.modules, {"boto3": boto3}):
            result = invoke_bedrock(
                payload={"layers": []},
                model_id="amazon.nova-lite-v1:0",
                region="us-east-1",
                request_metadata={"run-id": "test"},
            )
        request = client.converse.call_args.kwargs
        self.assertEqual(result["overall_risk"], "high")
        self.assertNotIn("outputConfig", request)
        self.assertNotIn("additionalModelRequestFields", request)
        self.assertEqual(
            request["toolConfig"]["toolChoice"]["tool"]["name"],
            "review_sanitized_tofu_plan",
        )

    def test_markdown_escapes_model_html(self):
        analysis = self.analysis()
        analysis["executive_summary"] = ["<script>alert(1)</script>"]
        markdown = render_markdown(analysis, model_id="test-model")
        self.assertNotIn("<script>", markdown)
        self.assertIn("&lt;script&gt;", markdown)

    def test_payload_prioritizes_destructive_changes(self):
        changes = [
            {"address": "late", "classification": "update"},
            {"address": "first", "classification": "delete"},
        ]
        payload = llm_payload(
            [
                {
                    "layer": "layer",
                    "summary": {},
                    "resource_changes": changes,
                }
            ]
        )
        self.assertEqual(payload["layers"][0]["resource_changes"][0]["address"], "first")

    def test_rejects_analysis_for_an_unexpected_layer(self):
        with self.assertRaises(ValueError):
            validate_analysis_layers(self.analysis(), {"security/us-east-1/security-audit"})

    def test_rejects_review_artifact_from_another_run(self):
        with tempfile.TemporaryDirectory() as directory:
            review = {
                "schema_version": 1,
                "metadata": {
                    "repository": "example/infrastructure",
                    "run_id": "old-run",
                    "head_sha": "old-head",
                },
            }
            Path(directory, "review.json").write_text(json.dumps(review))
            with self.assertRaises(ValueError):
                load_reviews(
                    Path(directory),
                    expected_metadata={
                        "repository": "example/infrastructure",
                        "run_id": "new-run",
                        "head_sha": "new-head",
                    },
                )


if __name__ == "__main__":
    unittest.main()
