"""Invoke a reviewed Amazon Bedrock model and read a schema-bound tool answer."""

from __future__ import annotations

from typing import Any

HAIKU_MODEL_ID = "us.anthropic.claude-haiku-5-5"
NOVA_LITE_MODEL_ID = "amazon.nova-lite-v1:0"
DEFAULT_MODEL_ID = HAIKU_MODEL_ID

# Reviewed models. The Bedrock role allows exactly these IDs, so any other
# value is rejected before invocation. Both return structured output through a
# forced, schema-bound tool call: Bedrock's JSON-schema output is not supported
# for Haiku 5.5. Haiku 5.5 also rejects `temperature`, and its adaptive
# thinking is disabled to keep the answer short and the latency low.
MODELS = {
    HAIKU_MODEL_ID: {
        "temperature": False,
        "request_fields": {"thinking": {"type": "disabled"}},
    },
    NOVA_LITE_MODEL_ID: {"temperature": True, "request_fields": {}},
}


def model_settings(model_id: str) -> dict:
    """Return the reviewed settings for a model, rejecting unreviewed IDs."""

    if model_id not in MODELS:
        raise ValueError(
            f"unsupported Bedrock model {model_id!r}; expected one of {sorted(MODELS)}"
        )
    return MODELS[model_id]


def inference_config(model_id: str, max_tokens: int) -> dict:
    config: dict[str, Any] = {"maxTokens": max_tokens}
    if model_settings(model_id)["temperature"]:
        config["temperature"] = 0
    return config


def tool_config(name: str, description: str, schema: dict) -> dict:
    return {
        "toolChoice": {"tool": {"name": name}},
        "tools": [
            {
                "toolSpec": {
                    "name": name,
                    "description": description,
                    "inputSchema": {"json": schema},
                }
            }
        ],
    }


def parse_tool_use(response: dict, name: str) -> dict:
    """Read the single, forced tool call used as structured output."""

    content = response.get("output", {}).get("message", {}).get("content", [])
    tool_inputs = [
        item["toolUse"].get("input")
        for item in content
        if isinstance(item, dict)
        and isinstance(item.get("toolUse"), dict)
        and item["toolUse"].get("name") == name
    ]
    if len(tool_inputs) != 1 or not isinstance(tool_inputs[0], dict):
        raise ValueError("Bedrock returned no usable structured tool response")
    return tool_inputs[0]


def invoke_tool(
    *,
    model_id: str,
    region: str,
    system_prompt: str,
    user_text: str,
    tool_name: str,
    tool_description: str,
    schema: dict,
    max_tokens: int,
    request_metadata: dict[str, str],
) -> tuple[dict, dict]:
    """Return the tool input and the response usage for one forced tool call."""

    settings = model_settings(model_id)  # Fail before importing or calling AWS.
    import boto3  # Imported lazily so unit tests need no AWS dependency.

    client = boto3.client("bedrock-runtime", region_name=region)
    request = {
        "modelId": model_id,
        "system": [{"text": system_prompt}],
        "messages": [{"role": "user", "content": [{"text": user_text}]}],
        "inferenceConfig": inference_config(model_id, max_tokens),
        "requestMetadata": request_metadata,
        "toolConfig": tool_config(tool_name, tool_description, schema),
    }
    if settings["request_fields"]:
        request["additionalModelRequestFields"] = settings["request_fields"]
    response = client.converse(**request)
    return parse_tool_use(response, tool_name), response.get("usage", {})
