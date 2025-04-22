import json
import os
import boto3
import uuid
from typing import Dict, Any
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()

s3_client = boto3.client('s3')
bedrock_runtime = boto3.client('bedrock-runtime')

def create_blueprint(document_type: str, required_fields: list) -> Dict[str, Any]:
    """
    Create a new processing blueprint using Bedrock
    """
    try:
        # Generate blueprint using Bedrock
        prompt = f"""
        Create a document processing blueprint for {document_type} with the following required fields:
        {json.dumps(required_fields, indent=2)}
        
        The blueprint should include:
        1. Document type
        2. Required fields with their types and validation rules
        3. Extraction rules for each field
        4. Processing instructions
        5. Confidence thresholds
        6. Required preprocessing steps
        
        Return the blueprint in this JSON format:
        {{
            "documentType": "string",
            "fields": [
                {{
                    "name": "string",
                    "type": "string",
                    "required": boolean,
                    "validation": {{
                        "format": "string",
                        "pattern": "string"
                    }},
                    "extractionRule": "string",
                    "confidenceThreshold": number
                }}
            ],
            "preprocessing": [
                {{
                    "step": "string",
                    "description": "string"
                }}
            ],
            "processingInstructions": "string"
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
        
        blueprint = json.loads(response['body'].read().decode('utf-8'))
        
        # Generate a unique blueprint ID
        blueprint_id = f"{document_type.lower().replace(' ', '_')}_{uuid.uuid4().hex[:8]}"
        
        # Save blueprint to S3
        s3_client.put_object(
            Bucket=os.environ['OUTPUT_BUCKET'],
            Key=f'blueprints/{blueprint_id}.json',
            Body=json.dumps(blueprint, indent=2)
        )
        
        return {
            "blueprintId": blueprint_id,
            "blueprint": blueprint,
            "status": "success"
        }
        
    except Exception as e:
        logger.error(f"Error creating blueprint: {str(e)}")
        raise

def update_blueprint(blueprint_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
    """
    Update an existing blueprint
    """
    try:
        # Get the existing blueprint
        response = s3_client.get_object(
            Bucket=os.environ['OUTPUT_BUCKET'],
            Key=f'blueprints/{blueprint_id}.json'
        )
        existing_blueprint = json.loads(response['Body'].read().decode('utf-8'))
        
        # Apply updates
        for key, value in updates.items():
            if key in existing_blueprint:
                existing_blueprint[key] = value
        
        # Save updated blueprint
        s3_client.put_object(
            Bucket=os.environ['OUTPUT_BUCKET'],
            Key=f'blueprints/{blueprint_id}.json',
            Body=json.dumps(existing_blueprint, indent=2)
        )
        
        return {
            "blueprintId": blueprint_id,
            "blueprint": existing_blueprint,
            "status": "success"
        }
        
    except Exception as e:
        logger.error(f"Error updating blueprint: {str(e)}")
        raise

def delete_blueprint(blueprint_id: str) -> Dict[str, Any]:
    """
    Delete an existing blueprint
    """
    try:
        # Delete the blueprint from S3
        s3_client.delete_object(
            Bucket=os.environ['OUTPUT_BUCKET'],
            Key=f'blueprints/{blueprint_id}.json'
        )
        
        return {
            "blueprintId": blueprint_id,
            "status": "deleted"
        }
        
    except Exception as e:
        logger.error(f"Error deleting blueprint: {str(e)}")
        raise

def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    try:
        # Extract the action and parameters from the event
        action = event.get('action')
        if not action:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'Missing action parameter',
                    'error': 'action is required'
                })
            }
        
        # Handle different actions
        if action == 'create':
            document_type = event.get('documentType')
            required_fields = event.get('requiredFields', [])
            if not document_type or not required_fields:
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'message': 'Missing required parameters',
                        'error': 'documentType and requiredFields are required for create action'
                    })
                }
            result = create_blueprint(document_type, required_fields)
            
        elif action == 'update':
            blueprint_id = event.get('blueprintId')
            updates = event.get('updates', {})
            if not blueprint_id or not updates:
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'message': 'Missing required parameters',
                        'error': 'blueprintId and updates are required for update action'
                    })
                }
            result = update_blueprint(blueprint_id, updates)
            
        elif action == 'delete':
            blueprint_id = event.get('blueprintId')
            if not blueprint_id:
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'message': 'Missing required parameter',
                        'error': 'blueprintId is required for delete action'
                    })
                }
            result = delete_blueprint(blueprint_id)
            
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'Invalid action',
                    'error': f'Unknown action: {action}'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
        
    except Exception as e:
        logger.exception("Error handling blueprint request")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error handling blueprint request',
                'error': str(e)
            })
        } 