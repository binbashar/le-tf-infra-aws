import json
import boto3
import os
from typing import Dict, Any
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()

s3_client = boto3.client('s3')
bedrock_runtime = boto3.client('bedrock-runtime')

def validate_document(document_data: Dict[str, Any], validation_rules: Dict[str, Any]) -> Dict[str, Any]:
    """
    Validate a processed document against the provided rules
    """
    validation_results = []
    is_valid = True

    for field, rules in validation_rules.items():
        field_value = document_data.get(field)
        field_valid = True
        messages = []

        # Check if field exists
        if field_value is None:
            field_valid = False
            messages.append(f"Field '{field}' is missing")
        else:
            # Check data type
            if 'type' in rules and not isinstance(field_value, eval(rules['type'])):
                field_valid = False
                messages.append(f"Field '{field}' has incorrect type. Expected {rules['type']}")

            # Check required
            if rules.get('required', False) and not field_value:
                field_valid = False
                messages.append(f"Field '{field}' is required but empty")

            # Check format
            if 'format' in rules:
                if rules['format'] == 'date' and not is_valid_date(field_value):
                    field_valid = False
                    messages.append(f"Field '{field}' has invalid date format")
                elif rules['format'] == 'email' and not is_valid_email(field_value):
                    field_valid = False
                    messages.append(f"Field '{field}' has invalid email format")

        if not field_valid:
            is_valid = False

        validation_results.append({
            "field": field,
            "isValid": field_valid,
            "message": "; ".join(messages) if messages else "Valid"
        })

    return {
        "isValid": is_valid,
        "validationResults": validation_results
    }

def is_valid_date(date_str: str) -> bool:
    """Check if a string is a valid date"""
    try:
        from datetime import datetime
        datetime.strptime(date_str, '%Y-%m-%d')
        return True
    except ValueError:
        return False

def is_valid_email(email: str) -> bool:
    """Check if a string is a valid email"""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))

def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    try:
        # Extract parameters from the event
        document_id = event.get('documentId')
        document_type = event.get('documentType')
        validation_rules = event.get('validationRules', {})

        if not document_id or not document_type:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'Missing required parameters',
                    'error': 'documentId and documentType are required'
                })
            }

        # Get the processed document from S3
        try:
            response = s3_client.get_object(
                Bucket=os.environ['OUTPUT_BUCKET'],
                Key=f'processed/{document_type}/{document_id}.json'
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

        # Validate the document
        validation_result = validate_document(document_data, validation_rules)

        return {
            'statusCode': 200,
            'body': json.dumps(validation_result)
        }

    except Exception as e:
        logger.exception("Error validating document")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error validating document',
                'error': str(e)
            })
        } 