# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import boto3
from os import environ
from botocore.exceptions import ClientError
from botocore.config import Config
import time
import random
from aws_lambda_powertools import Logger

# Getting configuration from environment variables
secret_name = environ.get('SECRET_NAME')
database = environ.get('DATABASE')
cluster_id = environ.get('CLUSTER_ID')

session = boto3.session.Session()
region = session.region_name

# Set up logging
logger = Logger()

# Initializing Secret Manager's client
logger.info("Initializing Secret Manager's client...")
client = session.client(
    service_name='secretsmanager',
        region_name=region
    )

try:
    logger.info(f"Retrieving secret {secret_name}...")
    get_secret_value_response = client.get_secret_value(
        SecretId=secret_name
    )
    secret_arn = get_secret_value_response['ARN']
    logger.info(f"Secret {secret_name} retrieved successfully.")
except ClientError as e:
    # For a list of exceptions thrown, see
    # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    logger.warning(f"Error retrieving secret {secret_name}: {e}")
    raise e

# Redshift Data API client
logger.info("Initializing Redshift Data API client...")
rsd = boto3.client(
    'redshift-data', 
    config=Config(connect_timeout=20, read_timeout=20, retries={'max_attempts': 2}))

@logger.inject_lambda_context
def lambda_handler(event, context):
    logger.info(f"Received event: {event}")
    
    action_group = event.get('actionGroup')
    api_path = event.get('apiPath')
    
    result = ''
    response_code = 200
    
    if api_path == '/redshiftQuery':
        result = redshift_query_handler(event)
    else:
        response_code = 404
        result = {"error": f"Unrecognized api path: {action_group}::{api_path}"}
    
    response_body = {
        'application/json': {
            'body': result
        }
    }
    
    action_response = {
        'actionGroup': action_group,
        'apiPath': api_path,
        'httpMethod': event.get('httpMethod'),
        'httpStatusCode': response_code,
        'responseBody': response_body
    }
    
    api_response = {'messageVersion': '1.0', 'response': action_response}
    return api_response

def redshift_query_handler(event):
    # Fetch parameters for the new fields

    # Extracting the SQL query
    query = event['requestBody']['content']['application/json']['properties'][0]['value']

    logger.info(f"the received QUERY: {query}")

    # Execute the query and wait for completion
    execution_id = execute_redshift_query(query)
    result = get_query_results(execution_id)
    logger.info(f"query result: {result}")

    return result

def execute_redshift_query(query):
    logger.info("executing redshift query...")
    resp = rsd.execute_statement(
        SecretArn=secret_arn,
        ClusterIdentifier=cluster_id,
        Database=database,
        Sql=query,
    )
    logger.info(f"response: {resp}")
    return resp['Id']

def get_query_results(statement_id, max_attempts=10, base_delay=1):
    attempt = 0
    while attempt < max_attempts:
        try:
            describe_statement = rsd.describe_statement(Id=statement_id)
            statement_status = describe_statement["Status"]
            if describe_statement["Status"] == "FINISHED":
                logger.info(f"Query Status - {statement_status}")
                break
            elif describe_statement["Status"] == "FAILED":
                logger.warning(f"Query Status - {statement_status}")
                error_message = f"Query Error - {describe_statement['Error']}"
                logger.warning(error_message)
                return error_message
            else:
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
    return rsd.get_statement_result(Id=statement_id)