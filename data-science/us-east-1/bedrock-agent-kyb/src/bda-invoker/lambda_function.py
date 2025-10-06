import json
import os
import boto3
from uuid import uuid4
from datetime import datetime, timezone

BDA_PROJECT_ARN = os.environ['BDA_PROJECT_ARN']
PROCESSING_BUCKET = os.environ['PROCESSING_BUCKET']
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')

bda_client = boto3.client('bedrock-data-automation-runtime', region_name=AWS_REGION)
s3_client = boto3.client('s3')
sts_client = boto3.client('sts')

AWS_ACCOUNT_ID = sts_client.get_caller_identity()['Account']
BDA_PROFILE_ARN = f'arn:aws:bedrock:{AWS_REGION}:{AWS_ACCOUNT_ID}:data-automation-profile/us.data-automation-v1'

def lambda_handler(event, context):
    bucket_name = event['detail']['bucket']['name']
    object_key = event['detail']['object']['key']
    object_etag = event['detail']['object'].get('etag', '')

    customer_id = extract_customer_id(object_key)
    correlation_id = str(uuid4())

    input_s3_uri = f"s3://{bucket_name}/{object_key}"
    output_s3_uri = f"s3://{PROCESSING_BUCKET}/standard/{customer_id}/"

    response = bda_client.invoke_data_automation_async(
        dataAutomationProfileArn=BDA_PROFILE_ARN,
        inputConfiguration={'s3Uri': input_s3_uri},
        outputConfiguration={'s3Uri': output_s3_uri},
        dataAutomationConfiguration={
            'dataAutomationProjectArn': BDA_PROJECT_ARN,
            'stage': 'LIVE'
        }
    )

    invocation_arn = response['invocationArn']

    metadata = {
        'correlation_id': correlation_id,
        'customer_id': customer_id,
        'input_bucket': bucket_name,
        'input_key': object_key,
        'input_etag': object_etag,
        'invocation_arn': invocation_arn,
        'timestamp': datetime.now(timezone.utc).isoformat() + 'Z',
        'status': 'initiated'
    }

    metadata_key = f"standard/{customer_id}/metadata.json"
    s3_client.put_object(
        Bucket=PROCESSING_BUCKET,
        Key=metadata_key,
        Body=json.dumps(metadata),
        ContentType='application/json'
    )

    return {
        'statusCode': 200,
        'body': json.dumps({
            'correlation_id': correlation_id,
            'invocation_arn': invocation_arn
        })
    }

def extract_customer_id(key):
    parts = key.split('/')
    return parts[0] if len(parts) > 1 else 'unknown'
