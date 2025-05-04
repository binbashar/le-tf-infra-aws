# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json
import logging
import os
import time
import traceback
import urllib.request
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

bda_client = None

def init_bda_client():
    \"\"\"Initializes the BDA client if not already done.\"\"\"
    global bda_client
    if bda_client is None:
        logger.info("Initializing Boto3 BedrockDataAutomation client")
        # Use the correct service name based on Boto3 documentation/availability
        # Assuming 'bedrock-data-automation' - this might need adjustment
        try:
            bda_client = boto3.client('bedrock-data-automation')
            logger.info("Boto3 BedrockDataAutomation client initialized successfully.")
        except Exception as e:
            logger.error(f"Failed to initialize Boto3 BedrockDataAutomation client: {e}")
            raise  # Re-raise the exception to fail the Lambda if client cannot be created

def find_project_by_name(project_name):
    \"\"\"Finds a BDA project identifier by its name.\"\"\"
    init_bda_client()
    logger.info(f"Searching for BDA project with name: {project_name}")
    try:
        # BDA API might not support filtering by name in list_projects
        # We might need to paginate through all projects
        paginator = bda_client.get_paginator('list_projects') # Assuming 'list_projects' exists
        for page in paginator.paginate():
            projects = page.get('projectSummaries', []) # Adjust key based on actual API response
            logger.debug(f"Checking page with {len(projects)} projects.")
            for project in projects:
                if project.get('name') == project_name:
                    project_id = project.get('projectIdentifier') # Adjust key
                    logger.info(f"Found existing project '{project_name}' with ID: {project_id}")
                    return project_id
        logger.info(f"No existing project found with name: {project_name}")
        return None
    except ClientError as e:
        # Handle potential errors like AccessDenied or ValidationException
        logger.error(f"Error listing BDA projects: {e}")
        # If list_projects doesn't exist, this will raise an error captured below
        raise
    except Exception as e:
        logger.error(f"Unexpected error finding project by name: {e}")
        logger.error(traceback.format_exc())
        raise

def create_project(project_name, project_description):
    \"\"\"Creates a new BDA project.\"\"\"
    init_bda_client()
    logger.info(f"Creating new BDA project with name: {project_name}")
    try:
        response = bda_client.create_data_automation_project( # Assuming 'create_data_automation_project'
            name=project_name,
            description=project_description
            # Add tags if needed
        )
        project_id = response.get('projectIdentifier') # Adjust key
        logger.info(f"Successfully created project '{project_name}' with ID: {project_id}")
        return project_id
    except ClientError as e:
        logger.error(f"Error creating BDA project '{project_name}': {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error creating project: {e}")
        logger.error(traceback.format_exc())
        raise

def delete_project(project_id):
    \"\"\"Deletes a BDA project.\"\"\"
    init_bda_client()
    logger.info(f"Deleting BDA project with ID: {project_id}")
    # Handle cases where creation failed and physical ID indicates failure
    if not project_id or project_id.startswith('failed-'):
         logger.warning(f"Skipping deletion for invalid or placeholder project ID: {project_id}")
         return True # Indicate success as there's nothing to delete
    try:
        bda_client.delete_data_automation_project( # Assuming 'delete_data_automation_project'
            projectIdentifier=project_id # Adjust parameter name
        )
        logger.info(f"Successfully initiated deletion for project ID: {project_id}")
        return True
    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code')
        # Assuming 'ResourceNotFoundException' is the code for not found
        if error_code == 'ResourceNotFoundException':
            logger.warning(f"Project ID {project_id} not found for deletion, assuming already deleted.")
            return True # Treat as success
        else:
            logger.error(f"Error deleting BDA project ID {project_id}: {e}")
            return False
    except Exception as e:
        logger.error(f"Unexpected error deleting project ID {project_id}: {e}")
        logger.error(traceback.format_exc())
        return False

def send_response(event, context, response_status, response_data, physical_resource_id=None, reason=None):
    \"\"\"Sends the response back to the CloudFormation pre-signed URL.\"\"\"
    response_url = event['ResponseURL']
    logger.info(f"Response URL: {response_url}")

    response_body = {
        'Status': response_status,
        'Reason': reason or f"See the details in CloudWatch Log Stream: {context.log_stream_name}",
        'PhysicalResourceId': physical_resource_id or context.log_stream_name,
        'StackId': event['StackId'],
        'RequestId': event['RequestId'],
        'LogicalResourceId': event['LogicalResourceId'],
        'Data': response_data
    }

    json_response_body = json.dumps(response_body)
    logger.info("Response body:")
    logger.info(json_response_body)

    headers = {
        'content-type': '',
        'content-length': str(len(json_response_body))
    }

    try:
        request = urllib.request.Request(response_url, data=json_response_body.encode('utf-8'), headers=headers, method='PUT')
        with urllib.request.urlopen(request) as response:
            logger.info(f"Status code: {response.getcode()}")
            logger.info(f"Status message: {response.msg}")
    except Exception as e:
        logger.error("Failed to send CFN response", exc_info=True)
        raise

def lambda_handler(event, context):
    \"\"\"Lambda handler for the CFN Custom Resource.\"\"\"
    logger.info("Received event:")
    logger.info(json.dumps(event))

    response_data = {}
    physical_resource_id = event.get('PhysicalResourceId') # Use existing one for Update/Delete if available
    status = 'FAILED' # Default to failure
    reason = None

    try:
        request_type = event['RequestType']
        props = event.get('ResourceProperties', {})
        project_name = props.get('ProjectName')
        project_description = props.get('ProjectDescription')

        if not project_name:
             raise ValueError("ProjectName property is required.")

        if request_type == 'Create' or request_type == 'Update':
            logger.info(f"Handling {request_type} request for project: {project_name}")
            # Check if project exists first
            found_id = find_project_by_name(project_name)
            if found_id:
                project_id = found_id
                logger.info("Using existing project ID.")
            else:
                # Create project if not found
                project_id = create_project(project_name, project_description)

            if project_id:
                physical_resource_id = project_id # Set physical ID to the actual project ID
                response_data['ProjectId'] = project_id
                status = 'SUCCESS'
            else:
                 # Should have raised exception, but handle just in case
                 reason = "Failed to create or find project ID."
                 physical_resource_id = f"failed-create-{event['RequestId']}"


        elif request_type == 'Delete':
            logger.info(f"Handling Delete request for PhysicalResourceId: {physical_resource_id}")
            if physical_resource_id:
                if delete_project(physical_resource_id):
                     status = 'SUCCESS'
                else:
                     reason = f"Failed to delete project ID {physical_resource_id}. Check logs."
            else:
                logger.warning("No PhysicalResourceId found for Delete request. Assuming success.")
                status = 'SUCCESS' # Nothing to delete

    except Exception as e:
        logger.error("Handler failed", exc_info=True)
        reason = str(e)
        # Use a stable-ish physical ID on complete failure to avoid CREATE_FAILED loops on stack update
        if request_type == 'Create':
             physical_resource_id = f"failed-create-{event['RequestId']}"
        # For Update/Delete, keep the existing physical_resource_id if available

    finally:
        # Ensure a response is always sent
        send_response(event, context, status, response_data, physical_resource_id, reason)

    return {
        'statusCode': 200, # Lambda execution itself succeeded, CFN status is in the response
        'body': json.dumps('Lambda handler finished.')
    } 