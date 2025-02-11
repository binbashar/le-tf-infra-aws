# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json
from aws_lambda_powertools import Logger

logger = Logger(use_rfc3339=True)

def generate_response(status_code: int, body: dict) -> dict:
    logger.info(f"Generating response with status code {status_code}")
    response = {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body),
        "isBase64Encoded": False
    }
    logger.info(response)
    return response