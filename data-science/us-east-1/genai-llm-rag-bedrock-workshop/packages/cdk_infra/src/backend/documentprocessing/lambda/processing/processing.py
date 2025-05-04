# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json
import os
import boto3
import time
from datetime import datetime
from typing import Dict, List, Any, Optional
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.validation import validate_event_schema
from botocore.exceptions import ClientError

# Initialize globals
logger = Logger()

# Get environment variables
OUTPUT_BUCKET = os.environ.get('OUTPUT_BUCKET')
INPUT_BUCKET = os.environ.get('INPUT_BUCKET')
METADATA_TABLE = os.environ.get('METADATA_TABLE')
BDA_PROJECT_ID = os.environ.get('BDA_PROJECT_ID')

# Initialize AWS clients with correct service names
s3_client = boto3.client('s3')
bda_build_client = boto3.client('bedrock-data-automation')
bda_runtime_client = boto3.client('bedrock-data-automation-runtime')
dynamodb = boto3.resource('dynamodb')
lambda_client = boto3.client('lambda')

# Get DynamoDB table
metadata_table = dynamodb.Table(METADATA_TABLE)

# Define schema for API validation
REQUEST_SCHEMA = {
    "type": "object",
    "properties": {
        "documentId": {"type": "string"},
        "pageNumber": {"type": "integer"},
        "blueprintId": {"type": "string"}
    },
    "required": ["documentId", "pageNumber"]
}

def detect_document_type(document_key: str) -> str:
    """
    Detect the document type from the filename by invoking the blueprint creation Lambda
    """
    try:
        # Find the blueprint creation Lambda function
        functions = lambda_client.list_functions()
        blueprint_lambda = None
        
        for function in functions['Functions']:
            if 'BlueprintCreation' in function['FunctionName']:
                blueprint_lambda = function['FunctionName']
                break
        
        if not blueprint_lambda:
            logger.error("BlueprintCreation Lambda not found")
            return "unknown"
        
        # Invoke the Lambda with document detection operation
        response = lambda_client.invoke(
            FunctionName=blueprint_lambda,
            InvocationType='RequestResponse',
            Payload=json.dumps({
                'operation': 'detect_document_type',
                'documentKey': document_key
            })
        )
        
        payload = json.loads(response['Payload'].read().decode('utf-8'))
        return payload.get('documentType', 'unknown')
        
    except Exception as e:
        logger.error(f"Error detecting document type: {str(e)}")
        return "unknown"

def get_blueprint_for_document_type(document_type: str) -> Optional[str]:
    """
    Get the blueprint ID for a document type by invoking the blueprint creation Lambda
    """
    try:
        # Find the blueprint creation Lambda function
        functions = lambda_client.list_functions()
        blueprint_lambda = None
        
        for function in functions['Functions']:
            if 'BlueprintCreation' in function['FunctionName']:
                blueprint_lambda = function['FunctionName']
                break
        
        if not blueprint_lambda:
            logger.error("BlueprintCreation Lambda not found")
            return None
        
        # Invoke the Lambda with get blueprint operation
        response = lambda_client.invoke(
            FunctionName=blueprint_lambda,
            InvocationType='RequestResponse',
            Payload=json.dumps({
                'operation': 'get_blueprint_for_document_type',
                'documentType': document_type
            })
        )
        
        payload = json.loads(response['Payload'].read().decode('utf-8'))
        return payload.get('blueprintId')
        
    except Exception as e:
        logger.error(f"Error getting blueprint for document type: {str(e)}")
        return None

def get_blueprint(blueprint_id: str) -> Dict[str, Any]:
    """
    Get the blueprint details from Bedrock Data Automation.
    
    Args:
        blueprint_id: The ARN of the blueprint
        
    Returns:
        The blueprint details
    """
    try:
        response = bda_build_client.get_blueprint(
            blueprintArn=blueprint_id
        )
        return response
    except ClientError as e:
        logger.error(f"Error getting blueprint {blueprint_id}: {str(e)}")
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        if error_code == 'ResourceNotFoundException':
            raise ValueError(f"Blueprint {blueprint_id} not found")
        raise

def list_blueprints(project_id: Optional[str] = None) -> List[Dict[str, Any]]:
    """
    List all available blueprints in Bedrock Data Automation.
    
    Args:
        project_id: The ARN of the project to filter by (optional)
        
    Returns:
        List of available blueprints
    """
    try:
        params = {}
        if project_id:
            params['projectFilter'] = {
                'projectArn': project_id
            }

        blueprints = []
        paginator = bda_build_client.get_paginator('list_blueprints')
        response_iterator = paginator.paginate(**params)

        for page in response_iterator:
            blueprints.extend(page.get('blueprints', []))

        return blueprints
    except ClientError as e:
        logger.error(f"Error listing blueprints: {str(e)}")
        raise

def process_document(document_id: str, page_number: int, blueprint_id: Optional[str] = None) -> Dict[str, Any]:
    """
    Process a document page using Bedrock Data Automation (synchronous polling).

    Args:
        document_id: The ID of the document
        page_number: The page number to process
        blueprint_id: Optional blueprint ARN to use for processing

    Returns:
        The processing results and status
    """
    try:
        # Input validation
        if not document_id:
            raise ValueError("document_id is required")
        if not isinstance(page_number, int) or page_number < 1:
            raise ValueError("page_number must be a positive integer")
        
        # Get the document page metadata
        logger.info(f"Retrieving metadata for document {document_id}, page {page_number}")
        response = metadata_table.get_item(
            Key={
                'documentId': document_id,
                'pageNumber': page_number
            }
        )
        
        if 'Item' not in response:
            raise ValueError(f"Document page not found: {document_id}, page {page_number}")
            
        page_data = response['Item']
        s3_key = page_data['s3Key']
        input_s3_uri = f"s3://{OUTPUT_BUCKET}/{s3_key}"
        
        # Update status to processing
        logger.info(f"Updating status to PROCESSING for document {document_id}, page {page_number}")
        metadata_table.update_item(
            Key={
                'documentId': document_id,
                'pageNumber': page_number
            },
            UpdateExpression='SET #status = :status, #lastUpdated = :lastUpdated',
            ExpressionAttributeNames={
                '#status': 'status',
                '#lastUpdated': 'lastUpdated'
            },
            ExpressionAttributeValues={
                ':status': 'PROCESSING',
                ':lastUpdated': datetime.now().isoformat()
            }
        )
        
        # Validate BDA project ID (ARN)
        if not BDA_PROJECT_ID:
            raise ValueError("BDA_PROJECT_ID environment variable is not set (should be Project ARN)")
        
        # If no blueprint_id (ARN) is provided, try to get appropriate blueprint ARN
        if not blueprint_id:
            document_type = detect_document_type(s3_key)
            logger.info(f"Detected document type: {document_type}")
            
            if document_type != "unknown":
                blueprint_id = get_blueprint_for_document_type(document_type)
                logger.info(f"Selected blueprint ID for {document_type}: {blueprint_id}")
        
        # Invoke Bedrock Data Automation Runtime Asynchronously
        logger.info(f"Invoking Bedrock Data Automation async for document {document_id}, page {page_number}")

        invoke_params = {
            'projectId': BDA_PROJECT_ID, # Use the Project ARN from env var
            's3Uri': input_s3_uri
        }

        if blueprint_id:
            # Verify blueprint exists using the ARN before using it
            try:
                get_blueprint(blueprint_id) # Check using ARN
                invoke_params['blueprintId'] = blueprint_id # Use ARN here
                logger.info(f"Using blueprint ARN {blueprint_id} for execution")
            except ValueError:
                logger.warning(f"Blueprint ARN {blueprint_id} not found, proceeding without blueprint")

        try:
            # Use the runtime client and invoke_data_automation_async
            bda_response = bda_runtime_client.invoke_data_automation_async(**invoke_params)
            job_id = bda_response['jobId'] # Get jobId
            logger.info(f"Started BDA job with ID: {job_id}")
        except ClientError as e:
            logger.error(f"Error invoking Bedrock Data Automation: {str(e)}")
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            if error_code == 'ResourceNotFoundException':
                raise ValueError(f"Project ID {BDA_PROJECT_ID} not found")
            raise

        # --- Polling Logic --- 
        max_wait_time = 600  # 10 minutes timeout
        start_time = time.time()
        status = 'IN_PROGRESS'
        status_response = {}

        logger.info(f"Polling status for job ID: {job_id}")
        while status == 'IN_PROGRESS' and (time.time() - start_time) < max_wait_time:
            try:
                # Check status using get_data_automation_status
                status_response = bda_runtime_client.get_data_automation_status(
                    jobId=job_id
                )
                status = status_response.get('status', 'ERROR') # Default to error if key missing
                logger.debug(f"Job {job_id} status: {status}")

                if status == 'IN_PROGRESS':
                    time.sleep(10) # Wait 10 seconds before checking again
                elif status not in ['COMPLETED', 'FAILED', 'PARTIALLY_FAILED', 'CANCELED']:
                    # Unexpected status, treat as error
                    logger.error(f"Unexpected status received: {status} for job {job_id}")
                    status = 'ERROR'
                    break

            except ClientError as e:
                logger.error(f"Error checking job status for {job_id}: {str(e)}")
                status = 'ERROR'
                break

        # Handle timeout
        if status == 'IN_PROGRESS':
            status = 'TIMED_OUT'
            logger.warning(f"Polling timed out for job {job_id}")

        # --- Process Results --- 
        result = {}
        final_status = 'FAILED' # Default final status unless completed

        if status == 'COMPLETED':
            logger.info(f"Processing completed for job {job_id}")
            final_status = 'COMPLETED'
            try:
                output_uri = status_response.get('outputLocation')
                if output_uri:
                    output_key = f"results/{document_id}/{page_number}/bda_result.json" # Define our desired key
                    source_bucket = output_uri.replace('s3://', '').split('/')[0]
                    source_key = '/'.join(output_uri.replace('s3://', '').split('/')[1:]) # Handle potential paths in key

                    logger.info(f"Copying results from s3://{source_bucket}/{source_key} to s3://{OUTPUT_BUCKET}/{output_key}")
                    s3_client.copy_object(
                        Bucket=OUTPUT_BUCKET,
                        Key=output_key,
                        CopySource={'Bucket': source_bucket, 'Key': source_key}
                    )

                    logger.info(f"Reading results from s3://{OUTPUT_BUCKET}/{output_key}")
                    content_response = s3_client.get_object(Bucket=OUTPUT_BUCKET, Key=output_key)
                    result = json.loads(content_response['Body'].read().decode('utf-8'))

                    # Update metadata with results
                    metadata_table.update_item(
                        Key={'documentId': document_id, 'pageNumber': page_number},
                        UpdateExpression='SET #status = :status, #lastUpdated = :lastUpdated, #outputKey = :outputKey, #result = :result',
                        ExpressionAttributeNames={'#status': 'status', '#lastUpdated': 'lastUpdated', '#outputKey': 'outputKey', '#result': 'result'},
                        ExpressionAttributeValues={':status': final_status, ':lastUpdated': datetime.now().isoformat(), ':outputKey': output_key, ':result': result}
                    )
                else:
                    logger.warning(f"Job {job_id} completed but no outputLocation found in status response.")
                    # Update metadata without results
                    metadata_table.update_item(
                        Key={'documentId': document_id, 'pageNumber': page_number},
                        UpdateExpression='SET #status = :status, #lastUpdated = :lastUpdated',
                        ExpressionAttributeNames={'#status': 'status', '#lastUpdated': 'lastUpdated'},
                        ExpressionAttributeValues={':status': final_status, ':lastUpdated': datetime.now().isoformat()}
                     )

            except Exception as res_err:
                logger.error(f"Error processing results for job {job_id}: {str(res_err)}")
                final_status = 'ERROR_POST_PROCESSING'
                # Update metadata with error
                metadata_table.update_item(
                     Key={'documentId': document_id, 'pageNumber': page_number},
                     UpdateExpression='SET #status = :status, #lastUpdated = :lastUpdated, #errorMessage = :errorMessage',
                     ExpressionAttributeNames={'#status': 'status', '#lastUpdated': 'lastUpdated', '#errorMessage': 'errorMessage'},
                     ExpressionAttributeValues={':status': final_status, ':lastUpdated': datetime.now().isoformat(), ':errorMessage': f"Error processing results: {str(res_err)}"}
                )
        else:
            # Handle FAILED, TIMED_OUT, ERROR, etc.
            final_status = status if status != 'ERROR' else 'FAILED' # Map internal ERROR to FAILED
            logger.warning(f"Processing ended with non-COMPLETED status: {final_status} for job {job_id}")
            error_message = status_response.get('failureReason', f"Processing ended with status: {final_status}")
            metadata_table.update_item(
                Key={'documentId': document_id, 'pageNumber': page_number},
                UpdateExpression='SET #status = :status, #lastUpdated = :lastUpdated, #errorMessage = :errorMessage',
                ExpressionAttributeNames={'#status': 'status', '#lastUpdated': 'lastUpdated', '#errorMessage': 'errorMessage'},
                ExpressionAttributeValues={':status': final_status, ':lastUpdated': datetime.now().isoformat(), ':errorMessage': error_message}
            )

        return {
            'documentId': document_id,
            'pageNumber': page_number,
            'jobId': job_id,
            'status': final_status,
            'result': result
        }

    except Exception as e:
        logger.error(f"Error processing document {document_id}, page {page_number}: {str(e)}")
        
        # Update document metadata with error if possible
        try:
            metadata_table.update_item(
                Key={
                    'documentId': document_id,
                    'pageNumber': page_number
                },
                UpdateExpression='SET #status = :status, #lastUpdated = :lastUpdated, #errorMessage = :errorMessage',
                ExpressionAttributeNames={
                    '#status': 'status',
                    '#lastUpdated': 'lastUpdated',
                    '#errorMessage': 'errorMessage'
                },
                ExpressionAttributeValues={
                    ':status': 'ERROR',
                    ':lastUpdated': datetime.now().isoformat(),
                    ':errorMessage': str(e)
                }
            )
        except Exception as update_error:
            logger.error(f"Error updating document status: {str(update_error)}")
        
        # Re-raise the original exception
        raise

@logger.inject_lambda_context(log_event=True)
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler to process a document using Bedrock Data Automation.
    
    Args:
        event: The Lambda event object containing document details
        context: The Lambda context
        
    Returns:
        The processing results
    """
    try:
        # Handle different event types
        if 'body' in event:
            # API Gateway event
            logger.info("Processing API Gateway event")
            try:
                body = json.loads(event['body'])
            except (TypeError, json.JSONDecodeError):
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'Invalid request body'})
                }
        elif 'detail' in event:
            # Event Bridge event
            logger.info("Processing EventBridge event")
            body = {
                'documentId': event['detail'].get('documentId'),
                'pageNumber': event['detail'].get('pageNumber'),
                'blueprintId': event['detail'].get('blueprintId')
            }
        else:
            # Direct invocation or Step Functions
            logger.info("Processing direct invocation")
            body = event
        
        # Validate input
        try:
            validate_event_schema(body, REQUEST_SCHEMA)
        except Exception as e:
            logger.error(f"Schema validation error: {str(e)}")
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': f'Invalid request: {str(e)}'
                })
            }
        
        document_id = body['documentId']
        page_number = body['pageNumber']
        blueprint_id = body.get('blueprintId')
        
        # Handle API operations
        if 'operation' in body:
            operation = body['operation']
            if operation == 'list_blueprints':
                logger.info("Listing blueprints")
                try:
                    blueprints = list_blueprints(BDA_PROJECT_ID)
                    return {
                        'statusCode': 200,
                        'body': json.dumps({
                            'blueprints': blueprints
                        })
                    }
                except Exception as e:
                    return {
                        'statusCode': 500,
                        'body': json.dumps({
                            'message': f'Error listing blueprints: {str(e)}'
                        })
                    }
            elif operation == 'get_blueprint' and 'blueprintId' in body:
                logger.info(f"Getting blueprint {blueprint_id}")
                try:
                    blueprint = get_blueprint(blueprint_id)
                    return {
                        'statusCode': 200,
                        'body': json.dumps(blueprint)
                    }
                except ValueError as e:
                    return {
                        'statusCode': 404,
                        'body': json.dumps({
                            'message': str(e)
                        })
                    }
                except Exception as e:
                    return {
                        'statusCode': 500,
                        'body': json.dumps({
                            'message': f'Error getting blueprint: {str(e)}'
                        })
                    }
        
        # Process document
        logger.info(f"Processing document {document_id}, page {page_number}")
        try:
            result = process_document(document_id, page_number, blueprint_id)
            return {
                'statusCode': 200,
                'body': json.dumps(result)
            }
        except ValueError as e:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'message': str(e)
                })
            }
        except Exception as e:
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'message': f'Error processing document: {str(e)}'
                })
            }
    
    except Exception as e:
        logger.error(f"Unhandled error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f'Unhandled error: {str(e)}'
            })
        } 