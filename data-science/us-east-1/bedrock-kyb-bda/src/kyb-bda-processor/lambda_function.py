import json
import boto3
import os
import urllib.parse
from datetime import datetime, timezone
import logging

logger = logging.getLogger()
logger.setLevel(getattr(logging, os.environ.get("LOG_LEVEL", "INFO").upper(), logging.INFO))

bedrock_client = boto3.client("bedrock-data-automation-runtime")
s3_client = boto3.client("s3")


def lambda_handler(event, context):
    """
    Lambda function to process KYB documents using Bedrock Data Automation.
    Triggered by S3 ObjectCreated events via EventBridge.
    """

    try:
        logger.info(f"Received event: {json.dumps(event)}")

        processed = 0
        failed = 0

        # EventBridge S3 Object Created (preferred)
        if event.get("source") == "aws.s3" and "detail" in event:
            detail = event["detail"]
            bucket_name = detail.get("bucket", {}).get("name")
            key_raw = detail.get("object", {}).get("key")
            object_key = urllib.parse.unquote_plus(key_raw) if key_raw else None
            if bucket_name and object_key:
                logger.info(f"Processing file: s3://{bucket_name}/{object_key}")
                if process_kyb_document(bucket_name, object_key):
                    processed += 1
                else:
                    failed += 1
            else:
                logger.error("Missing bucket name or object key in EventBridge event")

        # Direct S3 -> Lambda notifications (optional compatibility)
        elif "Records" in event:
            for rec in event.get("Records", []):
                s3 = rec.get("s3", {})
                bucket_name = s3.get("bucket", {}).get("name")
                key_raw = s3.get("object", {}).get("key")
                object_key = urllib.parse.unquote_plus(key_raw) if key_raw else None
                if bucket_name and object_key:
                    logger.info(f"Processing file: s3://{bucket_name}/{object_key}")
                    if process_kyb_document(bucket_name, object_key):
                        processed += 1
                    else:
                        failed += 1
                else:
                    logger.error("Missing bucket name or object key in S3 record")
        else:
            logger.warning("Unrecognized event shape; no work performed")

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Documents processed successfully",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                }
            ),
        }

    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        raise


def process_kyb_document(input_bucket, object_key):
    """
    Process a KYB document using Bedrock Data Automation.

    Args:
        input_bucket (str): The S3 bucket containing the input document
        object_key (str): The S3 object key of the document to process

    Returns:
        bool: True if processing was successful, False otherwise
    """

    try:
        # Get environment variables
        bda_project_arn = os.environ.get("BDA_PROJECT_ARN")
        bda_profile_arn = os.environ.get("BDA_PROFILE_ARN")
        output_bucket = os.environ.get("OUTPUT_BUCKET")

        if not bda_project_arn or not bda_profile_arn or not output_bucket:
            logger.error("Missing required environment variables")
            return False

        # Construct S3 URIs
        input_s3_uri = f"s3://{input_bucket}/{object_key}"

        # Generate output key with timestamp
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        base_name = os.path.splitext(object_key)[0]
        output_key = f"processed/{base_name}_{timestamp}.json"
        output_s3_uri = f"s3://{output_bucket}/{output_key}"

        logger.info(f"Input URI: {input_s3_uri}")
        logger.info(f"Output URI: {output_s3_uri}")

        # Generate clientToken with only alphanumeric and hyphens (AWS regex: [a-zA-Z0-9](-*[a-zA-Z0-9]){1,256})
        client_timestamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
        client_token = f"kyb-{client_timestamp}-{abs(hash(object_key)) % 10000}"

        # Invoke Bedrock Data Automation asynchronously
        response = bedrock_client.invoke_data_automation_async(
            dataAutomationProfileArn=bda_profile_arn,
            inputConfiguration={"s3Uri": input_s3_uri},
            outputConfiguration={"s3Uri": output_s3_uri},
            dataAutomationConfiguration={
                "dataAutomationProjectArn": bda_project_arn
            },
            clientToken=client_token,
        )

        invocation_arn = response.get("invocationArn")
        logger.info(f"BDA invocation started with ARN: {invocation_arn}")

        # Store invocation metadata in output bucket for tracking
        metadata = {
            "invocation_arn": invocation_arn,
            "input_s3_uri": input_s3_uri,
            "output_s3_uri": output_s3_uri,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "status": "processing",
        }

        metadata_key = f"metadata/{base_name}_{timestamp}_metadata.json"
        s3_client.put_object(
            Bucket=output_bucket,
            Key=metadata_key,
            Body=json.dumps(metadata, indent=2),
            ContentType="application/json",
        )

        return True

    except Exception as e:
        logger.error(f"Error processing document {object_key}: {str(e)}")
        return False
