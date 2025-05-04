# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

"""
KYB Blueprint Creation Package

This package provides functionality for creating and managing Know Your Business (KYB)
document processing blueprints in Amazon Bedrock Data Integration service.

It follows the patterns established in the AWS Bedrock Data Automation CDK construct.
"""

from .blueprint_creation import (
    create_project,
    create_blueprint,
    create_kyb_blueprints,
    detect_document_type,
    get_blueprint_for_document_type,
    list_blueprints,
    get_blueprint,
    delete_blueprint,
    update_blueprint,
    process_operation,
    lambda_handler
)

__all__ = [
    'create_project',
    'create_blueprint',
    'create_kyb_blueprints',
    'detect_document_type',
    'get_blueprint_for_document_type',
    'list_blueprints',
    'get_blueprint',
    'delete_blueprint',
    'update_blueprint',
    'process_operation',
    'lambda_handler'
] 