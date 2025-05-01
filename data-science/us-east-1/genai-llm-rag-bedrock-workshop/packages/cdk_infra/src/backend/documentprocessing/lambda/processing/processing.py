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
METADATA_TABLE = os.environ.get('METADATA_TABLE')
BDA_PROJECT_ID = os.environ.get('BDA_PROJECT_ID')

# Initialize AWS clients
s3_client = boto3.client('s3')
bedrock_client = boto3.client('bedrock')
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
        blueprint_id: The ID of the blueprint
        
    Returns:
        The blueprint details
    """
    try:
        response = bedrock_client.get_blueprint(
            blueprintId=blueprint_id
        )
        return response
    except ClientError as e:
        logger.error(f"Error getting blueprint {blueprint_id}: {str(e)}")
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        if error_code == 'ResourceNotFoundException':
            raise ValueError(f"Blueprint {blueprint_id} not found")
        raise

def list_blueprints() -> List[Dict[str, Any]]:
    """
    List all available blueprints in Bedrock Data Automation.
    
    Returns:
        List of available blueprints
    """
    try:
        blueprints = []
        response = bedrock_client.list_blueprints(projectId=BDA_PROJECT_ID)
        
        blueprints.extend(response.get('blueprints', []))
        
        next_token = response.get('nextToken')
        while next_token:
            response = bedrock_client.list_blueprints(
                projectId=BDA_PROJECT_ID,
                nextToken=next_token
            )
            blueprints.extend(response.get('blueprints', []))
            next_token = response.get('nextToken')
            
        return blueprints
    except ClientError as e:
        logger.error(f"Error listing blueprints: {str(e)}")
        raise

def process_document(document_id: str, page_number: int, blueprint_id: Optional[str] = None) -> Dict[str, Any]:
    """
    Process a document page using Bedrock Data Automation.
    
    Args:
        document_id: The ID of the document
        page_number: The page number to process
        blueprint_id: Optional blueprint ID to use for processing
        
    Returns:
        The processing results
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
        
        # Validate BDA project ID
        if not BDA_PROJECT_ID:
            raise ValueError("BDA_PROJECT_ID environment variable is not set")
        
        # If no blueprint_id is provided, try to detect document type and get appropriate blueprint
        if not blueprint_id:
            document_type = detect_document_type(s3_key)
            logger.info(f"Detected document type: {document_type}")
            
            if document_type != "unknown":
                blueprint_id = get_blueprint_for_document_type(document_type)
                logger.info(f"Selected blueprint ID for {document_type}: {blueprint_id}")
        
        # Invoke Bedrock Data Automation
        logger.info(f"Invoking Bedrock Data Automation for document {document_id}, page {page_number}")
        invoke_params = {
            'projectId': BDA_PROJECT_ID,
            's3Uri': f"s3://{OUTPUT_BUCKET}/{s3_key}"
        }
        
        if blueprint_id:
            # Verify blueprint exists before using it
            try:
                get_blueprint(blueprint_id)
                invoke_params['blueprintId'] = blueprint_id
                logger.info(f"Using blueprint {blueprint_id} for processing")
            except ValueError:
                logger.warning(f"Blueprint {blueprint_id} not found, proceeding without blueprint")
            
        try:
            bda_response = bedrock_client.invoke_data_automation_async(**invoke_params)
        except ClientError as e:
            logger.error(f"Error invoking Bedrock Data Automation: {str(e)}")
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            if error_code == 'ResourceNotFoundException':
                raise ValueError(f"Project ID {BDA_PROJECT_ID} not found")
            raise
        
        # Get the job ID
        job_id = bda_response['jobId']
        logger.info(f"Bedrock Data Automation job ID: {job_id}")
        
        # Wait for processing to complete (with timeout)
        max_wait_time = 600  # 10 minutes
        start_time = time.time()
        status = 'IN_PROGRESS'
        
        while status == 'IN_PROGRESS' and (time.time() - start_time) < max_wait_time:
            # Check status
            try:
                status_response = bedrock_client.get_data_automation_status(
                    jobId=job_id
                )
                status = status_response['status']
                
                if status == 'IN_PROGRESS':
                    # Wait before checking again
                    time.sleep(5)
            except ClientError as e:
                logger.error(f"Error checking job status: {str(e)}")
                status = 'ERROR'
                break
                
        # If still in progress after timeout, we'll consider it a failure
        if status == 'IN_PROGRESS':
            status = 'TIMED_OUT'
            logger.warning(f"Processing timed out for job {job_id}")
            
        # Get the results if completed successfully
        result = {}
        if status == 'COMPLETED':
            logger.info(f"Processing completed for job {job_id}")
            try:
                # Get the output document
                output_key = f"results/{document_id}/{page_number}/bda_result.json"
                
                # Get the S3 URI from the status response
                output_uri = status_response['outputLocation']
                
                # Extract source bucket and key from the output URI
                source_bucket = output_uri.replace('s3://', '').split('/')[0]
                source_key = output_uri.replace(f's3://{source_bucket}/', '')
                
                logger.info(f"Copying results from {source_bucket}/{source_key} to {OUTPUT_BUCKET}/{output_key}")
                
                # Copy to our output location
                s3_client.copy_object(
                    Bucket=OUTPUT_BUCKET,
                    Key=output_key,
                    CopySource={'Bucket': source_bucket, 'Key': source_key}
                )
                
                # Get the content
                content_response = s3_client.get_object(
                    Bucket=OUTPUT_BUCKET,
                    Key=output_key
                )
                
                result = json.loads(content_response['Body'].read().decode('utf-8'))
                
                # Update document metadata with results
                logger.info(f"Updating metadata with results for document {document_id}, page {page_number}")
                metadata_table.update_item(
                    Key={
                        'documentId': document_id,
                        'pageNumber': page_number
                    },
                    UpdateExpression='SET #status = :status, #lastUpdated = :lastUpdated, #outputKey = :outputKey, #result = :result, #documentType = :documentType',
                    ExpressionAttributeNames={
                        '#status': 'status',
                        '#lastUpdated': 'lastUpdated',
                        '#outputKey': 'outputKey',
                        '#result': 'result',
                        '#documentType': 'documentType'
                    },
                    ExpressionAttributeValues={
                        ':status': 'COMPLETED',
                        ':lastUpdated': datetime.now().isoformat(),
                        ':outputKey': output_key,
                        ':result': result,
                        ':documentType': detect_document_type(s3_key)
                    }
                )
            except Exception as e:
                logger.error(f"Error processing results: {str(e)}")
                status = 'ERROR'
                
                # Update metadata with error
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
                        ':errorMessage': f"Error processing results: {str(e)}"
                    }
                )
        else:
            # Update document metadata with failure
            logger.warning(f"Processing failed with status: {status} for document {document_id}, page {page_number}")
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
                    ':status': 'FAILED',
                    ':lastUpdated': datetime.now().isoformat(),
                    ':errorMessage': f"Processing failed with status: {status}"
                }
            )
            
        return {
            'documentId': document_id,
            'pageNumber': page_number,
            'jobId': job_id,
            'status': status,
            'result': result
        }
        
    except Exception as e:
        logger.error(f"Error processing document: {str(e)}")
        
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
                    blueprints = list_blueprints()
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