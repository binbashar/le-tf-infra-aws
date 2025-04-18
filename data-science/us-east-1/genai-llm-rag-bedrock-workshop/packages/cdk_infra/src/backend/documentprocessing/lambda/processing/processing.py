import json
import boto3
import os
from typing import Dict, Any
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()

s3_client = boto3.client('s3')
bedrock_runtime = boto3.client('bedrock-runtime')

def get_blueprint(blueprint_id: str) -> Dict[str, Any]:
    """
    Get the processing blueprint from S3
    """
    try:
        response = s3_client.get_object(
            Bucket=os.environ['OUTPUT_BUCKET'],
            Key=f'blueprints/{blueprint_id}.json'
        )
        return json.loads(response['Body'].read().decode('utf-8'))
    except Exception as e:
        logger.error(f"Error reading blueprint from S3: {str(e)}")
        raise

def process_document(document_data: Dict[str, Any], blueprint: Dict[str, Any]) -> Dict[str, Any]:
    """
    Process a document according to the blueprint
    """
    processed_data = {}
    metadata = {
        "processingSteps": [],
        "confidenceScores": {}
    }

    for field in blueprint.get('fields', []):
        field_name = field['name']
        extraction_rule = field.get('extractionRule')
        
        # Apply extraction rule
        try:
            if extraction_rule:
                # Use Bedrock to extract the field value
                prompt = f"""
                Extract the {field_name} from the following document data:
                {json.dumps(document_data)}
                
                Extraction rule: {extraction_rule}
                
                Return the extracted value in JSON format:
                {{
                    "value": "extracted_value",
                    "confidence": 0.95
                }}
                """
                
                response = bedrock_runtime.invoke_model(
                    modelId='anthropic.claude-3-sonnet-20240229-v1:0',
                    body=json.dumps({
                        "prompt": prompt,
                        "max_tokens": 1000,
                        "temperature": 0.7
                    })
                )
                
                result = json.loads(response['body'].read().decode('utf-8'))
                processed_data[field_name] = result['value']
                metadata['confidenceScores'][field_name] = result['confidence']
            else:
                # Direct mapping if no extraction rule
                processed_data[field_name] = document_data.get(field_name)
                metadata['confidenceScores'][field_name] = 1.0
                
            metadata['processingSteps'].append({
                "field": field_name,
                "status": "success",
                "rule": extraction_rule
            })
            
        except Exception as e:
            logger.error(f"Error processing field {field_name}: {str(e)}")
            metadata['processingSteps'].append({
                "field": field_name,
                "status": "error",
                "error": str(e)
            })

    return {
        "processedDocument": processed_data,
        "processingMetadata": metadata
    }

def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    try:
        # Extract parameters from the event
        document_id = event.get('documentId')
        document_type = event.get('documentType')
        blueprint_id = event.get('blueprintId')
        processing_options = event.get('processingOptions', {})

        if not all([document_id, document_type, blueprint_id]):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'Missing required parameters',
                    'error': 'documentId, documentType, and blueprintId are required'
                })
            }

        # Get the document from S3
        try:
            response = s3_client.get_object(
                Bucket=os.environ['INPUT_BUCKET'],
                Key=f'{document_type}/{document_id}'
            )
            document_data = json.loads(response['Body'].read().decode('utf-8'))
        except Exception as e:
            logger.error(f"Error reading document from S3: {str(e)}")
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'message': 'Document not found',
                    'error': str(e)
                })
            }

        # Get the blueprint
        try:
            blueprint = get_blueprint(blueprint_id)
        except Exception as e:
            logger.error(f"Error getting blueprint: {str(e)}")
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'message': 'Blueprint not found',
                    'error': str(e)
                })
            }

        # Process the document
        result = process_document(document_data, blueprint)

        # Save the processed document
        s3_client.put_object(
            Bucket=os.environ['OUTPUT_BUCKET'],
            Key=f'processed/{document_type}/{document_id}.json',
            Body=json.dumps(result['processedDocument'])
        )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'status': 'success',
                'processedDocument': result['processedDocument'],
                'processingMetadata': result['processingMetadata']
            })
        }

    except Exception as e:
        logger.exception("Error processing document")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error processing document',
                'error': str(e)
            })
        } 