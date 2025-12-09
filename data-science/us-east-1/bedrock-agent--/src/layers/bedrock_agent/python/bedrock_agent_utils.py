import json
import logging
import uuid
from typing import Any, Dict

import structlog


def configure_structured_logging():
    import os

    log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
    logging.basicConfig(level=getattr(logging, log_level, logging.INFO), force=True)

    structlog.configure(
        processors=[
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.add_log_level,
            structlog.processors.JSONRenderer(),
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )


configure_structured_logging()


def get_structured_logger(correlation_id: str = None):
    logger = structlog.get_logger()
    if correlation_id:
        logger = logger.bind(correlation_id=correlation_id)
    return logger


def parse_request(event: Dict[str, Any]) -> Dict[str, Any]:
    correlation_id = str(uuid.uuid4())

    return {
        "action_group": event.get("actionGroup", ""),
        "api_path": event.get("apiPath", ""),
        "http_method": event.get("httpMethod", ""),
        "parameters": _extract_parameters(event),
        "correlation_id": correlation_id,
    }


def _extract_parameters(event: Dict[str, Any]) -> Dict[str, Any]:
    parameters = {}

    # Standard parameters array
    if "parameters" in event and isinstance(event["parameters"], list):
        for param in event["parameters"]:
            if isinstance(param, dict) and "name" in param and "value" in param:
                parameters[param["name"]] = param["value"]

    # Request body properties
    if "requestBody" in event:
        content = event.get("requestBody", {}).get("content", {})
        if "application/json" in content:
            json_content = content["application/json"]
            # Properties form
            if isinstance(json_content.get("properties"), list):
                for prop in json_content["properties"]:
                    if isinstance(prop, dict) and "name" in prop and "value" in prop:
                        parameters[prop["name"]] = prop["value"]
            # Body string form
            body = json_content.get("body")
            if isinstance(body, str):
                try:
                    parsed = json.loads(body)
                    if isinstance(parsed, dict):
                        parameters.update(parsed)
                except Exception:
                    pass

    return parameters


def format_response(
    status_code: int,
    body: Dict[str, Any],
    action_group: str,
    api_path: str,
    http_method: str,
) -> Dict[str, Any]:
    return {
        "messageVersion": "1.0",
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


def format_error(
    error: Exception,
    status_code: int,
    action_group: str,
    api_path: str,
    http_method: str,
) -> Dict[str, Any]:
    return format_response(
        status_code=status_code,
        body={"error": str(error), "statusCode": status_code},
        action_group=action_group,
        api_path=api_path,
        http_method=http_method,
    )
