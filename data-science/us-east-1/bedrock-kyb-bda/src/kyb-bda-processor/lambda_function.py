import json
import boto3
import os
import urllib.parse
from datetime import datetime, UTC
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

bedrock_client = boto3.client("bedrock-data-automation-runtime")
s3_client = boto3.client("s3")


def lambda_handler(event, context):
    """
    Lambda function to process KYB documents using Bedrock Data Automation.
    Triggered by S3 ObjectCreated events via EventBridge.
    """

    try:
        logger.info(f"Received event: {json.dumps(event)}")

        # Extract S3 event information from EventBridge event
        for record in event.get("Records", []):
            if record.get("source") == "aws.s3":
                detail = record.get("detail", {})
                bucket_name = detail.get("bucket", {}).get("name")
                object_key = urllib.parse.unquote_plus(
                    detail.get("object", {}).get("key")
                )

                if not bucket_name or not object_key:
                    logger.error("Missing bucket name or object key in event")
                    continue

                logger.info(f"Processing file: s3://{bucket_name}/{object_key}")

                # Process the document with Bedrock Data Automation
                result = process_kyb_document(bucket_name, object_key)

                if result:
                    logger.info(f"Successfully processed document: {object_key}")
                else:
                    logger.error(f"Failed to process document: {object_key}")

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Documents processed successfully",
                    "timestamp": datetime.now(UTC).isoformat(),
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
        output_bucket = os.environ.get("OUTPUT_BUCKET")

        if not bda_project_arn or not output_bucket:
            logger.error("Missing required environment variables")
            return False

        # Construct S3 URIs
        input_s3_uri = f"s3://{input_bucket}/{object_key}"

        # Generate output key with timestamp
        timestamp = datetime.now(UTC).strftime("%Y%m%d_%H%M%S")
        base_name = os.path.splitext(object_key)[0]
        output_key = f"processed/{base_name}_{timestamp}.json"
        output_s3_uri = f"s3://{output_bucket}/{output_key}"

        logger.info(f"Input URI: {input_s3_uri}")
        logger.info(f"Output URI: {output_s3_uri}")

        # Invoke Bedrock Data Automation asynchronously
        response = bedrock_client.invoke_data_automation_async(
            inputConfiguration={"s3InputConfiguration": {"s3Uri": input_s3_uri}},
            outputConfiguration={"s3OutputConfiguration": {"s3Uri": output_s3_uri}},
            dataAutomationConfiguration={
                "dataAutomationProjectArn": bda_project_arn,
                "stage": "LIVE"
            },
            clientToken=f"kyb-{timestamp}-{hash(object_key) % 10000}",
        )

        invocation_arn = response.get("invocationArn")
        logger.info(f"BDA invocation started with ARN: {invocation_arn}")

        # Store invocation metadata in output bucket for tracking
        metadata = {
            "invocation_arn": invocation_arn,
            "input_s3_uri": input_s3_uri,
            "output_s3_uri": output_s3_uri,
            "timestamp": datetime.now(UTC).isoformat(),
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
