# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json
import os
import boto3
import re
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Callable
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

# Initialize globals
logger = Logger()

# Get environment variables
METADATA_TABLE = os.environ.get('METADATA_TABLE')

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

# Get DynamoDB table
metadata_table = dynamodb.Table(METADATA_TABLE)

def is_valid_date(date_string: str) -> bool:
    """
    Check if a string is a valid date in common formats.
    
    Args:
        date_string: The date string to validate
        
    Returns:
        True if the date is valid, False otherwise
    """
    # Simple pattern matching for common date formats
    date_patterns = [
        r'^\d{2}/\d{2}/\d{4}$',  # MM/DD/YYYY
        r'^\d{2}-\d{2}-\d{4}$',  # MM-DD-YYYY
        r'^\d{4}/\d{2}/\d{2}$',  # YYYY/MM/DD
        r'^\d{4}-\d{2}-\d{2}$',  # YYYY-MM-DD
        r'^\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4}$',  # DD Month YYYY
    ]
    
    for pattern in date_patterns:
        if re.match(pattern, date_string):
            return True
            
    return False

def is_valid_email(email: str) -> bool:
    """
    Check if a string is a valid email address.
    
    Args:
        email: The email address to validate
        
    Returns:
        True if the email is valid, False otherwise
    """
    # Basic email validation pattern
    email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(email_pattern, email))

def validate_document(document_id: str, page_number: int, validation_rules: Optional[Dict[str, Dict[str, Any]]] = None) -> Dict[str, Any]:
    """
    Validate a processed document against validation rules.
    
    Args:
        document_id: The ID of the document to validate
        page_number: The page number to validate
        validation_rules: Optional validation rules to apply
        
    Returns:
        Validation results
    """
    try:
        # Get the document page metadata
        response = metadata_table.get_item(
            Key={
                'documentId': document_id,
                'pageNumber': page_number
            }
        )
        
        if 'Item' not in response:
            raise ValueError(f"Document page not found: {document_id}, page {page_number}")
            
        page_data = response['Item']
        
        # Check if the document has been processed
        if page_data.get('status') != 'COMPLETED':
            raise ValueError(f"Document page not ready for validation: {document_id}, page {page_number}, status: {page_data.get('status')}")
            
        # Get the processing results
        result = page_data.get('result', {})
        
        # Apply validation rules
        validation_results = {
            'isValid': True,
            'validationErrors': [],
            'validationWarnings': []
        }
        
        # Default validation rules if none provided
        if validation_rules is None:
            validation_rules = {
                'requiredFields': {
                    'type': 'required',
                    'fields': ['title', 'date', 'content']
                },
                'emailFields': {
                    'type': 'email',
                    'fields': ['email']
                },
                'dateFields': {
                    'type': 'date',
                    'fields': ['date', 'dueDate', 'issuedDate']
                }
            }
            
        # Apply each rule
        for rule_name, rule_config in validation_rules.items():
            rule_type = rule_config.get('type')
            fields = rule_config.get('fields', [])
            
            if rule_type == 'required':
                # Check required fields
                for field in fields:
                    if field not in result or not result[field]:
                        validation_results['isValid'] = False
                        validation_results['validationErrors'].append({
                            'field': field,
                            'rule': 'required',
                            'message': f"Field '{field}' is required but missing or empty"
                        })
                        
            elif rule_type == 'email':
                # Validate email fields
                for field in fields:
                    if field in result and result[field] and not is_valid_email(result[field]):
                        validation_results['isValid'] = False
                        validation_results['validationErrors'].append({
                            'field': field,
                            'rule': 'email',
                            'message': f"Field '{field}' is not a valid email address: {result[field]}"
                        })
                        
            elif rule_type == 'date':
                # Validate date fields
                for field in fields:
                    if field in result and result[field] and not is_valid_date(result[field]):
                        validation_results['validationWarnings'].append({
                            'field': field,
                            'rule': 'date',
                            'message': f"Field '{field}' may not be a valid date: {result[field]}"
                        })
            
            elif rule_type == 'custom' and 'validator' in rule_config:
                # Apply custom validation function
                validator = rule_config['validator']
                for field in fields:
                    if field in result and not validator(result[field]):
                        validation_results['validationWarnings'].append({
                            'field': field,
                            'rule': 'custom',
                            'message': f"Field '{field}' failed custom validation"
                        })
                        
        # Update document metadata with validation results
        metadata_table.update_item(
            Key={
                'documentId': document_id,
                'pageNumber': page_number
            },
            UpdateExpression='SET #status = :status, #lastUpdated = :lastUpdated, #validationResults = :validationResults',
            ExpressionAttributeNames={
                '#status': 'status',
                '#lastUpdated': 'lastUpdated',
                '#validationResults': 'validationResults'
            },
            ExpressionAttributeValues={
                ':status': 'VALIDATED',
                ':lastUpdated': datetime.now().isoformat(),
                ':validationResults': validation_results
            }
        )
        
        return {
            'documentId': document_id,
            'pageNumber': page_number,
            'validationResults': validation_results
        }
        
    except Exception as e:
        logger.error(f"Error validating document: {str(e)}")
        
        # Update document metadata with error
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
                    ':status': 'VALIDATION_ERROR',
                    ':lastUpdated': datetime.now().isoformat(),
                    ':errorMessage': str(e)
                }
            )
        except Exception as update_error:
            logger.error(f"Error updating document status: {str(update_error)}")
            
        raise

@logger.inject_lambda_context(log_event=True)
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler for document validation.
    
    Args:
        event: Lambda event containing document details
        context: Lambda context
        
    Returns:
        Validation results
    """
    try:
        document_id = event.get('documentId')
        page_number = event.get('pageNumber')
        validation_rules = event.get('validationRules')
        
        if not document_id or page_number is None:
            raise ValueError("Missing required parameters: documentId and pageNumber")
            
        result = validate_document(document_id, page_number, validation_rules)
        return result
        
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        raise 