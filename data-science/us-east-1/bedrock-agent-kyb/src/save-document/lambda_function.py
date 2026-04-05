import json
import os
import uuid
from datetime import datetime, timezone

import boto3

OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]
s3_client = boto3.client("s3")


def lambda_handler(event, context):
    """Bedrock Agent action group handler for saving KYB verdicts"""

    message_version = event.get("messageVersion", "1.0")
    action_group = event["actionGroup"]
    api_path = event["apiPath"]
    http_method = event["httpMethod"]

    session_attrs = event.get("sessionAttributes", {})
    customer_id = session_attrs.get("customer_id")

    if not customer_id:
        return create_response(
            message_version,
            action_group,
            api_path,
            http_method,
            400,
            {"error": "customer_id required in session attributes"},
        )

    parameters = parse_request_body(event)
    verdict_data = parameters.get("content")

    if not verdict_data:
        return create_response(
            message_version,
            action_group,
            api_path,
            http_method,
            400,
            {"error": "content parameter required"},
        )

    if isinstance(verdict_data, str):
        try:
            verdict_data = json.loads(verdict_data)
        except json.JSONDecodeError:
            pass

    now = datetime.now(timezone.utc)
    file_uuid = str(uuid.uuid4())
    s3_key = f"{customer_id}/yyyy={now.year}/mm={now.month:02d}/dd={now.day:02d}/{file_uuid}.json"

    s3_client.put_object(
        Bucket=OUTPUT_BUCKET,
        Key=s3_key,
        Body=json.dumps(verdict_data, default=str, indent=2),
        ContentType="application/json",
    )

    response_body = {
        "status": "success",
        "customer_id": customer_id,
        "s3_key": s3_key,
        "timestamp": now.isoformat(),
    }

    return create_response(
        message_version,
        action_group,
        api_path,
        http_method,
        200,
        response_body,
    )


def parse_request_body(event):
    """Parse parameters from Bedrock Agent request body"""
    parameters = {}

    # Handle GET-style parameters
    if "parameters" in event and isinstance(event["parameters"], list):
        for param in event["parameters"]:
            if isinstance(param, dict) and "name" in param:
                parameters[param["name"]] = param.get("value", "")

    # Handle POST-style requestBody
    if "requestBody" in event and isinstance(event["requestBody"], dict):
        content = event["requestBody"].get("content", {})

        if "application/json" in content:
            json_content = content["application/json"]

            # Handle properties list
            if isinstance(json_content, dict) and "properties" in json_content:
                properties = json_content["properties"]
                if isinstance(properties, list):
                    for prop in properties:
                        if isinstance(prop, dict):
                            prop_name = prop.get("name")
                            prop_value = prop.get("value")
                            if prop_name and prop_value is not None:
                                parameters[prop_name] = prop_value

    print(f"[DEBUG] Extracted parameters: {list(parameters.keys())}")
    return parameters


def create_response(
    message_version,
    action_group,
    api_path,
    http_method,
    status_code,
    body,
):
    """Create Bedrock Agent response format"""
    return {
        "messageVersion": message_version,
        "response": {
            "actionGroup": action_group,
            "apiPath": api_path,
            "httpMethod": http_method,
            "httpStatusCode": status_code,
            "responseBody": {
                "application/json": {"body": json.dumps(body, default=str)}
            },
        },
    }
