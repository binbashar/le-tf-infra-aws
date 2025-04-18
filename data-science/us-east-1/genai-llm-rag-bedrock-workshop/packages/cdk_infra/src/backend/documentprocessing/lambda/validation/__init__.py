"""
Document Validation Lambda Package

This package contains the Lambda function for validating processed documents.
It provides functionality to validate document fields against specified rules
and return validation results.
"""

from .validation import validate_document, is_valid_date, is_valid_email, lambda_handler

__all__ = ['validate_document', 'is_valid_date', 'is_valid_email', 'lambda_handler'] 