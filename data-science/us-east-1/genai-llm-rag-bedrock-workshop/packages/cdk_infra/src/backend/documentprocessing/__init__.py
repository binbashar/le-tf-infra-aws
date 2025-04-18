"""
Document Processing Package

This package contains the Lambda functions and utilities for processing and validating documents.
It includes functionality for document processing, validation, and blueprint management.
"""

from .lambda.validation import validate_document, is_valid_date, is_valid_email
from .lambda.processing import get_blueprint, process_document

__all__ = [
    'validate_document',
    'is_valid_date',
    'is_valid_email',
    'get_blueprint',
    'process_document'
] 