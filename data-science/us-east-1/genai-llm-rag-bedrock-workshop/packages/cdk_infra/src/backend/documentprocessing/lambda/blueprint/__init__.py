"""
Document Blueprint Creation Lambda Package

This package contains the Lambda function for creating and managing document processing blueprints.
It provides functionality to define document schemas, field extraction rules, and validation criteria.
"""

from .blueprint import create_blueprint, update_blueprint, delete_blueprint, lambda_handler

__all__ = ['create_blueprint', 'update_blueprint', 'delete_blueprint', 'lambda_handler'] 