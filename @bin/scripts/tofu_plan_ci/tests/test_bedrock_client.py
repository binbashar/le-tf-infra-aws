import sys
import types
import unittest
from unittest.mock import Mock, patch

from tofu_plan_ci.bedrock_client import inference_config, invoke_tool, parse_tool_use


def tool_response(name="answer", payload=None):
    return {
        "output": {
            "message": {
                "content": [{"toolUse": {"name": name, "input": payload or {"ok": True}}}]
            }
        },
        "usage": {"inputTokens": 10, "outputTokens": 5},
    }


class BedrockClientTests(unittest.TestCase):
    def invoke(self, model_id, client):
        boto3 = types.ModuleType("boto3")
        boto3.client = Mock(return_value=client)
        with patch.dict(sys.modules, {"boto3": boto3}):
            return invoke_tool(
                model_id=model_id,
                region="us-east-1",
                system_prompt="system",
                user_text="user",
                tool_name="answer",
                tool_description="Return the answer.",
                schema={"type": "object"},
                max_tokens=100,
                request_metadata={"run-id": "test"},
            )

    def test_unreviewed_models_are_rejected_before_invocation(self):
        for model_id in ("amazon.nova-pro-v1:0", "us.anthropic.claude-sonnet-4-6"):
            with self.subTest(model_id=model_id), self.assertRaises(ValueError):
                self.invoke(model_id, Mock())

    def test_claude_5_requests_omit_temperature(self):
        self.assertEqual(inference_config("us.anthropic.claude-haiku-5-5", 100), {"maxTokens": 100})
        self.assertEqual(
            inference_config("amazon.nova-lite-v1:0", 100), {"maxTokens": 100, "temperature": 0}
        )

    def test_haiku_forces_the_tool_without_thinking(self):
        client = Mock()
        client.converse.return_value = tool_response()
        result, usage = self.invoke("us.anthropic.claude-haiku-5-5", client)
        request = client.converse.call_args.kwargs
        self.assertEqual(result, {"ok": True})
        self.assertEqual(usage["inputTokens"], 10)
        self.assertEqual(request["toolConfig"]["toolChoice"]["tool"]["name"], "answer")
        self.assertNotIn("outputConfig", request)
        self.assertEqual(
            request["additionalModelRequestFields"], {"thinking": {"type": "disabled"}}
        )

    def test_nova_forces_the_tool_with_temperature(self):
        client = Mock()
        client.converse.return_value = tool_response()
        self.invoke("amazon.nova-lite-v1:0", client)
        request = client.converse.call_args.kwargs
        self.assertNotIn("additionalModelRequestFields", request)
        self.assertEqual(request["inferenceConfig"]["temperature"], 0)

    def test_a_missing_or_other_tool_answer_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_tool_use(tool_response(name="other"), "answer")
        with self.assertRaises(ValueError):
            parse_tool_use({"output": {"message": {"content": [{"text": "{}"}]}}}, "answer")


if __name__ == "__main__":
    unittest.main()
