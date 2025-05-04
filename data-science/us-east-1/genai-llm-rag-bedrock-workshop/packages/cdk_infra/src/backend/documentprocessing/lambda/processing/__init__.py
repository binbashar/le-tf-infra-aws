# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

"""
Document Processing Lambda Package

This package contains the Lambda function for processing documents.
It provides functionality to process documents according to specified blueprints,
extract fields using Bedrock, and store processed results.
"""

from .processing import get_blueprint, process_document, lambda_handler

__all__ = ['get_blueprint', 'process_document', 'lambda_handler'] 