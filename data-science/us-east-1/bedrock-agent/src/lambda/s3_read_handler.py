import os

import boto3
from bedrock_agent_utils import (
    format_error,
    format_response,
    get_structured_logger,
    parse_request,
)

s3_client = boto3.client("s3")


def lambda_handler(event, context):
    request = parse_request(event)
    logger = get_structured_logger(request["correlation_id"])

    logger.info(
        "bedrock_request_received",
        action_group=request["action_group"],
        api_path=request["api_path"],
        http_method=request["http_method"],
    )

    try:
        if request["api_path"].startswith("/read"):
            return handle_read_request(request, logger)
        else:
            logger.warning("unknown_api_path", api_path=request["api_path"])
            return format_error(
                Exception(f"Unknown API path: {request['api_path']}"),
                404,
                request["action_group"],
                request["api_path"],
                request["http_method"],
            )

    except Exception as e:
        logger.error(
            "request_processing_failed", error=str(e), error_type=type(e).__name__
        )
        return format_error(
            e, 500, request["action_group"], request["api_path"], request["http_method"]
        )


def handle_read_request(request, logger):
    parameters = request["parameters"]

    key = parameters.get("key")
    bucket = parameters.get("bucket", os.environ.get("DOCUMENTS_BUCKET"))

    if not key:
        logger.warning("missing_parameter", parameter="key")
        return format_error(
            ValueError("Missing required parameter: key"),
            400,
            request["action_group"],
            request["api_path"],
            request["http_method"],
        )

    if not bucket:
        logger.warning("missing_parameter", parameter="bucket")
        return format_error(
            ValueError("Missing required parameter: bucket"),
            400,
            request["action_group"],
            request["api_path"],
            request["http_method"],
        )

    try:
        logger.info("s3_read_initiated", operation="read", bucket=bucket, key=key)

        response = s3_client.get_object(Bucket=bucket, Key=key)
        content = response["Body"].read().decode("utf-8")

        response_body = {
            "content": content,
            "metadata": {
                "key": key,
                "bucket": bucket,
                "contentType": response.get("ContentType", "text/plain"),
                "contentLength": response.get("ContentLength", 0),
                "lastModified": response.get("LastModified", "").isoformat()
                if response.get("LastModified")
                else None,
            },
        }

        logger.info(
            "s3_read_completed",
            operation="read",
            bucket=bucket,
            key=key,
            content_size=len(content),
        )

        return format_response(
            200,
            response_body,
            request["action_group"],
            request["api_path"],
            request["http_method"],
        )

    except s3_client.exceptions.NoSuchKey:
        logger.warning("s3_object_not_found", bucket=bucket, key=key)
        return format_error(
            Exception(f"Object not found: {key}"),
            404,
            request["action_group"],
            request["api_path"],
            request["http_method"],
        )
    except s3_client.exceptions.NoSuchBucket:
        logger.warning("s3_bucket_not_found", bucket=bucket)
        return format_error(
            Exception(f"Bucket not found: {bucket}"),
            404,
            request["action_group"],
            request["api_path"],
            request["http_method"],
        )
    except Exception as e:
        logger.error(
            "s3_operation_failed",
            operation="read",
            bucket=bucket,
            key=key,
            error=str(e),
            error_type=type(e).__name__,
        )
        return format_error(
            e, 500, request["action_group"], request["api_path"], request["http_method"]
        )
