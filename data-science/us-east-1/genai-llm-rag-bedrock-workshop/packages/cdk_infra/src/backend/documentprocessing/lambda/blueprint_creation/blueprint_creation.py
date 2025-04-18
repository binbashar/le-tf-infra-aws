import json
import os
import boto3
from typing import Dict, Any
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()

s3_client = boto3.client('s3')
bedrock_runtime = boto3.client('bedrock-runtime')

def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    try:
        # Extract the document type and fields from the event
        document_type = event.get('documentType', '')
        required_fields = event.get('requiredFields', [])
        
        # Create a prompt for the Bedrock model
        prompt = f"""
        Create a document processing blueprint for {document_type} that extracts the following fields:
        {', '.join(required_fields)}
        
        The blueprint should include:
        1. Field extraction rules
        2. Validation rules
        3. Confidence thresholds
        4. Required preprocessing steps
        
        Format the response as a JSON object with the following structure:
        {{
            "blueprint": {{
                "documentType": "string",
                "fields": [
                    {{
                        "name": "string",
                        "type": "string",
                        "extractionRule": "string",
                        "validationRule": "string",
                        "confidenceThreshold": number,
                        "required": boolean
                    }}
                ],
                "preprocessing": [
                    {{
                        "step": "string",
                        "description": "string"
                    }}
                ]
            }}
        }}
        """
        
        # Call Bedrock to generate the blueprint
        response = bedrock_runtime.invoke_model(
            modelId='anthropic.claude-3-sonnet-20240229-v1:0',
            body=json.dumps({
                "prompt": prompt,
                "max_tokens": 1000,
                "temperature": 0.7
            })
        )
        
        # Parse the response
        response_body = json.loads(response['body'].read())
        blueprint = json.loads(response_body['completion'])
        
        # Save the blueprint to S3
        s3_client.put_object(
            Bucket=os.environ['S3_OUTPUT_BUCKET'],
            Key=f'blueprints/{document_type}_blueprint.json',
            Body=json.dumps(blueprint, indent=2)
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Blueprint created successfully',
                'blueprint': blueprint
            })
        }
        
    except Exception as e:
        logger.exception("Error creating blueprint")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error creating blueprint',
                'error': str(e)
            })
        } 