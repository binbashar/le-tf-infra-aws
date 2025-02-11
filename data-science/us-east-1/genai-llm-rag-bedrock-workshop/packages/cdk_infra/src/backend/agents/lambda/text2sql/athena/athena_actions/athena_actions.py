# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import re
from aws_lambda_powertools import Logger
from aws_lambda_powertools.event_handler import BedrockAgentResolver
from athena_utils import execute_and_get_results, initialize_s3_output
from error_utils import get_error_response
from request_utils import get_property_value
from response_utils import create_api_response

app = BedrockAgentResolver()
logger = Logger()

s3_output = initialize_s3_output()

@logger.inject_lambda_context
def lambda_handler(event, context):
    logger.info(f"Received event: {event}")
    
    try:
        properties = event['requestBody']['content']['application/json']['properties']
        query = get_property_value(
            properties,
            'query',
            'MISSING_QUERY',
            'QUERY',
            event
        )
        if isinstance(query, dict):
            query = preprocess_query(query)
            return query
        
        logger.info(f"Executing query: {query}")
        result = execute_and_get_results(query, s3_output)
        if isinstance(result, str):  # If it's an error message
            return create_api_response(
                event,
                400,
                get_error_response('QUERY_EXECUTION_FAILED')
            )

        return create_api_response(event, 200, result)

    except Exception as e:
        logger.exception(f"Error in lambda_handler: {str(e)}")
        return create_api_response(
            event,
            500,
            {
                'error': 'INTERNAL_ERROR',
                'message': str(e),
                'hint': 'This is an unexpected error. Please make sure your query follows the correct format and try again'
            }
        )


def preprocess_query(query):
    # Check if the query contains a date comparison
    date_pattern = r"(datetime|date)\s+BETWEEN\s+'(\d{4}-\d{2}-\d{2})'\s+AND\s+'(\d{4}-\d{2}-\d{2})'"
    match = re.search(date_pattern, query, re.IGNORECASE)
    
    if match:
        # If it does, replace the string dates with TIMESTAMP
        column, start_date, end_date = match.groups()
        modified_query = query.replace(
            f"{column} BETWEEN '{start_date}' AND '{end_date}'",
            f"{column} BETWEEN TIMESTAMP '{start_date}' AND TIMESTAMP '{end_date}'"
        )
        return modified_query
    
    # If no date comparison is found, return the original query
    return query