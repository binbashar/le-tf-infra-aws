# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

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
        api_path = event.get('apiPath')
        
        database_name = get_property_value(
            properties,
            'database', 
            'MISSING_DATABASE_NAME', 
            'LIST_TABLES',
            event
        )
        if isinstance(database_name, dict):
            return database_name
        
        if api_path == '/list_tables':
            return list_tables(event, database_name)
        
        elif api_path == '/describe_table':
            table_name = get_property_value(
                properties, 
                'table', 
                'MISSING_TABLE_NAME', 
                'TABLE_SCHEMA',
                event
            )
            if isinstance(table_name, dict):
                return table_name
                
            return describe_table(event, database_name, table_name)

        else:
            return create_api_response(
                event,
                404,
                get_error_response('INVALID_API_PATH_SCHEMA')
            )

    except Exception as e:
        logger.exception(f"Error in lambda_handler: {str(e)}")
        return create_api_response(
            event,
            500,
            get_error_response('INTERNAL_ERROR')
        )

      
@app.post("/list_tables", description="Retrieve a list of all tables in the specified database")
def list_tables(event, database_name):
    
    query = f"SHOW TABLES IN {database_name}"
    logger.info(f"Executing query: {query}")
    
    result = execute_and_get_results(query, s3_output)
    
    if isinstance(result, dict) and 'error' in result:
        logger.warning(f"Error listing tables: {result['error']}")
        return create_api_response(
            event,
            400,
            get_error_response('QUERY_RESULT_ERROR')
        )

    return create_api_response(event, 200, result)


@app.post("/describe_table", description="Retrieve the schema information of a specific table")
def describe_table(event, database_name, table_name):
    logger.info(f"Reading {table_name} schema in {database_name} database...")
    
    query = f"DESCRIBE {database_name}.{table_name}"
    logger.info(f"Executing query: {query}")
    
    result = execute_and_get_results(query, s3_output)
    
    if not isinstance(result, dict) or 'error' not in result:
        formatted_result = {
            "table_name": table_name,
            "database": database_name,
            "columns": result
        }
        result = formatted_result
    
    http_status_code = 400 if isinstance(result, dict) and 'error' in result else 200
    final_response = create_api_response(event, http_status_code, result)
    logger.info(f"Final response: {final_response}")

    return create_api_response(event, 200, result)