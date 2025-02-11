# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import boto3
import time
import random
from os import environ
from aws_lambda_powertools import Logger

logger = Logger()
athena_client = boto3.client('athena')

def initialize_s3_output(env_var_name='S3_OUTPUT'):
    """Initialize S3 output location from environment variable"""
    s3_output = environ.get(env_var_name)
    if not s3_output:
        raise Exception(f"{env_var_name} environment variable is not set")
    return f"s3://{s3_output}/query-results/"


def execute_athena_query(query, s3_output):
    try:
        logger.info(f"Executing query: {query}")
        response = athena_client.start_query_execution(
            QueryString=query,
            ResultConfiguration={'OutputLocation': s3_output}
        )
        execution_id = response['QueryExecutionId']
        logger.info(f"Athena query execution started with ID: {execution_id}")
        return execution_id
    except Exception as e:
        logger.error(f"Failed to start query execution: {str(e)}")
        raise


def get_query_execution_details(execution_id):
    try:
        response = athena_client.get_query_execution(QueryExecutionId=execution_id)
        execution_details = response['QueryExecution']
        state = execution_details['Status']['State']
        reason = execution_details['Status'].get('StateChangeReason', 'No reason provided')

        logger.info(f"Query execution state: {state}")
        logger.info(f"Query execution details: {execution_details}")

        return state, reason, execution_details
    except Exception as e:
        logger.error(f"Failed to get query execution details: {str(e)}")
        raise

def get_query_results(execution_id, max_attempts=10, base_delay=1):
    attempt = 0
    while attempt < max_attempts:
        try:
            state, reason, execution_details = get_query_execution_details(execution_id)
            
            if state in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                break
            
            # Exponential backoff with jitter
            delay = min(base_delay * (2 ** attempt), 120)   # Cap at 120 seconds
            logger.info(f"Query is not ready. Attempt {attempt + 1}. Retrying in {delay} seconds.")
            jitter = random.uniform(0, 0.1 * delay)
            time.sleep(delay + jitter)

            attempt += 1
            
        except Exception as e:
            logger.error(f"Error in attempt {attempt + 1}: {str(e)}")
            attempt += 1
            time.sleep(base_delay)

    if state == 'SUCCEEDED':
        response = athena_client.get_query_results(QueryExecutionId=execution_id)
        logger.info(f"The SUCCEEDED Query result: {response}")
        
        # Process and format the results
        columns = [col['Label'] for col in response['ResultSet']['ResultSetMetadata']['ColumnInfo']]

        rows = response['ResultSet']['Rows']
        formatted_results = []
        for row in rows:
            formatted_row = {}
            for i, value in enumerate(row['Data']):
                formatted_row[columns[i]] = value.get('VarCharValue', '')
            formatted_results.append(formatted_row)
        return formatted_results
    
    else:
        error_message = f"Query failed with status '{state}'. Reason: {reason}"
        logger.error(error_message)
        logger.error(f"Full execution details: {execution_details}")
        return {'error': error_message}
    

def execute_and_get_results(query, s3_output):
    """Execute query and return results"""
    execution_id = execute_athena_query(query, s3_output)
    return get_query_results(execution_id)