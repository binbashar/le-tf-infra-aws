# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

ERROR_MESSAGES = {
    'MISSING_PROPERTIES': {
        'message': 'No properties provided in the request',
        'hint': 'Please provide the required parameters based on the API endpoint'
    },
    'MISSING_QUERY': {
        'message': 'Query is required',
        'hint': 'No query was provided. Please provide a SQL query to execute'
    },
    'MISSING_DATABASE_NAME': {
        'message': 'Database name is required',
        'hint': 'Please provide the database name using the "database" parameter'
    },
    'MISSING_TABLE_NAME': {
        'message': 'Table name is required',
        'hint': 'Please provide the table name using the "table" parameter'
    },
    'QUERY_EXECUTION_FAILED': {
        'message': 'Failed to execute query',
        'hint': 'Please use fully qualified table names. Example: SELECT * FROM ecommerce_data.products LIMIT 1'
    },
    'QUERY_RESULT_ERROR': {
        'message': 'Error occurred while getting query results',
        'hint': 'Check if the tables and columns in your query exist and you have proper permissions'
    },
    'INVALID_API_PATH_SCHEMA': {
        'message': 'Unknown API path',
        'hint': 'Available endpoints are: /describe_table, /list_tables'
    },
    'INVALID_API_PATH_QUERY': {
        'message': 'Unknown API path',
        'hint': 'Available endpoint is: /athena_query'
    },
    'INTERNAL_ERROR': {
        'message': 'An unexpected error occurred',
        'hint': 'Please try again or contact support'
    },
}

EXAMPLES = {
    'TABLE_SCHEMA': {
        'database': 'ecommerce_data',
        'table': 'products'
    },
    'QUERY': {
        'simple': 'SELECT * FROM ecommerce_data.products LIMIT 1',
        'with_condition': 'SELECT * FROM ecommerce_data.orders WHERE order_date >= TIMESTAMP \'2024-01-01\''
    },
    'LIST_TABLES': {
        'database': 'ecommerce_data'
    }
}


def get_error_response(error_code, example_type=None, **kwargs):
    """
    Get formatted error response with optional dynamic content and specific example
    """
    error_info = ERROR_MESSAGES.get(error_code, ERROR_MESSAGES['INTERNAL_ERROR']).copy()
    
    if 'message' in kwargs:
        error_info['message'] = error_info['message'] + f": {kwargs['message']}"
    
    response = {
        'error': error_code,
        **error_info
    }

    if example_type and example_type in EXAMPLES:
        response['example'] = EXAMPLES[example_type]
    
    return response