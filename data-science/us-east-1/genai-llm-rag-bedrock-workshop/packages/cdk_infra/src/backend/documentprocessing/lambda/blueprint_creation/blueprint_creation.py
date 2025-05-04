# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

"""
Blueprint Creation Module

This module provides functions to create and manage Bedrock Data Automation blueprints
for KYB (Know Your Business) document processing.
"""

import os
import json
import logging
import boto3
import time
from datetime import datetime
import traceback
from aws_lambda_powertools import Logger

# Configure logging
logger = Logger()

# Initialize AWS clients for Bedrock Data Automation
# Use the correct service name based on Boto3 documentation
bda_client = boto3.client('bedrock-data-automation')

# Load blueprint definitions
KYB_BLUEPRINTS_FILE = os.path.join(os.path.dirname(__file__), 'kyb_blueprints.json')
try:
    with open(KYB_BLUEPRINTS_FILE, 'r') as f:
        KYB_BLUEPRINTS = json.load(f)
except Exception as e:
    logger.error(f"Error loading KYB blueprints: {str(e)}")
    KYB_BLUEPRINTS = {}

def create_project(project_name=None, description=None):
    """
    Create a Bedrock Data Automation project.
    
    Args:
        project_name (str, optional): Name of the project
        description (str, optional): Project description
        
    Returns:
        dict: Project creation response
    """
    if project_name is None:
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        project_name = f"kyb-project-{timestamp}"
    
    if description is None:
        description = "KYB Document Processing Project for Automated Document Analysis"
        
    try:
        # Use the correct method name from bedrock-data-automation
        response = bda_client.create_data_automation_project(
            name=project_name,
            description=description
        )
        # Assuming response structure might change slightly, adjust key access if needed
        logger.info(f"Created project: {project_name} with ID: {response.get('projectIdentifier')}")
        return response
    except Exception as e:
        logger.error(f"Error creating project '{project_name}': {str(e)}")
        raise

def create_kyb_blueprints(project_id=None, blueprints_config=None):
    """
    Create all KYB blueprints defined in the configuration.
    
    Args:
        project_id (str, optional): Project ID. If not provided, a new project is created.
        blueprints_config (dict, optional): Blueprint configurations. 
                                           If not provided, loads from default file.
    
    Returns:
        dict: Object containing project details and created blueprints
    """
    # Load blueprint definitions if not provided
    if blueprints_config is None:
        blueprints_config = KYB_BLUEPRINTS
    
    # Create a project if not provided
    if project_id is None:
        # Check environment variable for project ID
        project_id = os.environ.get('BDA_PROJECT_ID')
        
        # If still None, create a new project
        if project_id is None:
            project_response = create_project()
            project_id = project_response.get('projectIdentifier') # Likely new key
            project_info = {
                'projectId': project_id,
                'projectName': project_response.get('name'),
                'created': True
            }
        else:
            project_info = {
                'projectId': project_id,
                'created': False
            }
    else:
        project_info = {
            'projectId': project_id,
            'created': False
        }
    
    # Create each blueprint
    created_blueprints = []
    for blueprint_type, blueprint_data in blueprints_config.items():
        try:
            # Extract blueprint name and the pre-defined schema object
            blueprint_name = blueprint_data.get('name', f"kyb-{blueprint_type}-blueprint")
            blueprint_schema_dict = blueprint_data.get('schema')

            if not blueprint_schema_dict:
                logger.warning(f"Schema definition missing for blueprint type '{blueprint_type}'. Skipping.")
                created_blueprints.append({
                    "type": blueprint_type,
                    "status": "skipped",
                    "error": "Missing schema definition in kyb_blueprints.json"
                })
                continue

            # Convert the pre-defined schema dictionary to a JSON string
            blueprint_schema_string = json.dumps(blueprint_schema_dict)
            logger.info(f"Attempting to create blueprint '{blueprint_name}' with pre-defined schema string: {blueprint_schema_string}")

            # Create the blueprint passing the name and the schema string
            response = bda_client.create_blueprint(
                blueprintName=blueprint_name,
                type='DOCUMENT', # Assuming all are document types
                schema=blueprint_schema_string
            )
            
            # Record the created blueprint
            created_blueprints.append({
                "type": blueprint_type,
                "id": response.get('blueprintIdentifier'), # Adapt if key name is different
                "name": blueprint_name,
                "status": "created"
            })
            
        except Exception as e:
            logger.error(f"Failed to create blueprint for {blueprint_type}: {str(e)}")
            # Log the schema that failed
            logger.error(f"Failing schema string for {blueprint_type}: {blueprint_schema_string}")
            created_blueprints.append({
                "type": blueprint_type,
                "status": "failed",
                "error": str(e)
            })
    
    # Return the results
    return {
        "project": project_info,
        "blueprints": created_blueprints,
        "summary": {
            "total": len(blueprints_config),
            "created": sum(1 for bp in created_blueprints if bp.get('status') == 'created'),
            "failed": sum(1 for bp in created_blueprints if bp.get('status') == 'failed')
        }
    }

def detect_document_type(document_data):
    """
    Detect the type of KYB document based on its content.
    
    Args:
        document_data (dict): Document data to analyze
        
    Returns:
        str: Detected document type
    """
    # Simple document type detection logic
    document_type = None
    
    if not document_data:
        return None
        
    data_str = str(document_data).lower()
    
    if "passport" in data_str:
        document_type = "passport"
    elif "ein" in data_str or "employer identification" in data_str:
        document_type = "ein_verification"
    elif "1120" in data_str or "income tax" in data_str:
        document_type = "income_tax_1120"
    elif "formation" in data_str or "incorporation" in data_str:
        document_type = "company_formation"
    elif "actionary" in data_str or "composition" in data_str:
        document_type = "actionary_composition"
    
    logger.info(f"Detected document type: {document_type}")
    return document_type

def get_blueprint_for_document_type(document_type):
    """
    Get the blueprint definition for a specific document type.
    
    Args:
        document_type (str): Document type
        
    Returns:
        dict: Blueprint definition for the document type
    """
    blueprint_mapping = {
        "passport": "passportBlueprint",
        "ein_verification": "einVerificationBlueprint",
        "income_tax_1120": "form1120Blueprint",
        "company_formation": "companyFormationBlueprint",
        "actionary_composition": "actionaryCompositionBlueprint"
    }
    
    blueprint_key = blueprint_mapping.get(document_type)
    if not blueprint_key:
        return {}
        
    return KYB_BLUEPRINTS.get(blueprint_key, {})

def list_blueprints(project_id=None):
    """
    List all blueprints or blueprints for a specific project.

    Args:
        project_id (str, optional): Project ARN to filter blueprints.

    Returns:
        dict: List of blueprints
    """
    try:
        params = {}
        if project_id:
            # Use projectFilter with projectArn as per docs
            params['projectFilter'] = {
                'projectArn': project_id
            }

        # Use the correct client and paginator name
        paginator = bda_client.get_paginator('list_blueprints')
        response_iterator = paginator.paginate(**params)

        all_blueprints = []
        for page in response_iterator:
            # Use the correct response key 'blueprints' as per docs
            all_blueprints.extend(page.get('blueprints', []))

        logger.info(f"Found {len(all_blueprints)} blueprints for project ARN: {project_id or 'all projects'}")
        return {"blueprints": all_blueprints}
    except Exception as e:
        logger.error(f"Error listing blueprints for project {project_id}: {str(e)}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        raise

def get_blueprint_by_type(project_id, document_type):
    """
    Find a blueprint by its associated document type (based on naming convention).

    Args:
        project_id (str): The project ARN to search within.
        document_type (str): The document type (e.g., 'ein_verification').

    Returns:
        dict: Details of the found blueprint or None if not found.
    """
    try:
        logger.info(f"Searching for blueprint of type '{document_type}' in project '{project_id}'")
        # Expected naming convention, adjust if different
        expected_blueprint_name = f"kyb-{document_type}-blueprint"

        list_response = list_blueprints(project_id=project_id)
        blueprints = list_response.get("blueprints", [])

        for blueprint in blueprints:
            # Use keys from list_blueprints response summary (blueprintName, blueprintArn)
            if blueprint.get('blueprintName') == expected_blueprint_name:
                logger.info(f"Found matching blueprint: ARN={blueprint.get('blueprintArn')}, Name={blueprint.get('blueprintName')}")
                return blueprint # Return the summary details

        logger.warning(f"No blueprint found with name '{expected_blueprint_name}' for document type '{document_type}' in project '{project_id}'.")
        return None # Indicate not found
    except Exception as e:
        logger.error(f"Error getting blueprint by type '{document_type}' for project {project_id}: {str(e)}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        raise # Propagate error

def get_blueprint(blueprint_id):
    """
    Get details of a specific blueprint.
    
    Args:
        blueprint_id (str): Blueprint ID
        
    Returns:
        dict: Blueprint details
    """
    try:
        # Use the correct method name and parameter from bedrock-data-automation docs
        response = bda_client.get_blueprint(
            blueprintArn=blueprint_id # Use blueprintArn as required by docs
        )
        return response
    except Exception as e:
        logger.error(f"Error getting blueprint {blueprint_id}: {str(e)}")
        raise

def delete_blueprint(blueprint_id):
    """
    Delete a blueprint.

    Args:
        blueprint_id (str): ARN of the Blueprint to delete

    Returns:
        dict: Deletion response
    """
    try:
        # Use the correct parameter name from bedrock-data-automation docs
        response = bda_client.delete_blueprint(
            blueprintArn=blueprint_id # Use blueprintArn as required by docs
        )
        return response
    except Exception as e:
        logger.error(f"Error deleting blueprint {blueprint_id}: {str(e)}")
        raise

def update_blueprint(blueprint_id, definition):
    """
    Update a blueprint's definition.

    Args:
        blueprint_id (str): ARN of the Blueprint to update
        definition (dict): New blueprint definition (Python dict)

    Returns:
        dict: Update response
    """
    try:
        # Convert schema dictionary to JSON string as required by the API
        schema_string = json.dumps(definition)

        # Use the correct parameter names from bedrock-data-automation docs
        response = bda_client.update_blueprint(
            blueprintArn=blueprint_id, # Use blueprintArn
            schema=schema_string      # Use schema (as string)
        )
        return response
    except Exception as e:
        logger.error(f"Error updating blueprint {blueprint_id}: {str(e)}")
        raise

def process_operation(event):
    """
    Process the incoming API Gateway event based on the operation specified.

    Args:
        event (dict): API Gateway Lambda proxy event

    Returns:
        dict: Response object for API Gateway
    """
    try:
        # Check if the event came from EventBridge
        if 'detail' in event and 'source' in event and event['source'] == 'custom.bedrock.blueprint':
            logger.info("Processing EventBridge event detail")
            body = event.get('detail', {})
            operation = body.get('operation')
        else:
            # Existing logic for Agent/API Gateway calls
            body = json.loads(event.get('body', '{}'))
            if 'requestBody' in event:
                input_body_str = event['requestBody'].get('content', {}).get('application/json', {}).get('properties', [])
                body = {prop['name']: prop['value'] for prop in input_body_str if 'name' in prop and 'value' in prop}
            operation = body.get('operation')

        logger.info(f"Processing operation: {operation} with body: {json.dumps(body)}")

        response_body = {}
        status_code = 200

        if operation == 'create_blueprints':
            project_id = body.get('project_id')
            response_body = create_kyb_blueprints(project_id=project_id)
        elif operation == 'list_blueprints':
            project_id = body.get('project_id')
            response_body = list_blueprints(project_id=project_id)
        elif operation == 'get_blueprint':
            blueprint_arn = body.get('blueprintArn') # Changed from blueprint_id
            if not blueprint_arn:
                status_code = 400
                response_body = {'message': 'Missing required parameter: blueprintArn'}
            else:
                response_body = get_blueprint(blueprint_arn) # Pass the ARN
                if response_body is None:
                     status_code = 404
                     response_body = {'message': f'Blueprint with ARN {blueprint_arn} not found'}
        elif operation == 'GET_BLUEPRINT_BY_TYPE' or operation == 'GET':
            project_id = os.environ.get('BDA_PROJECT_ID') # Assuming project ID is in env
            document_type = body.get('document_type')
            if not project_id or not document_type:
                status_code = 400
                response_body = {'message': 'Missing required parameter: document_type (or Project ID not configured)'}
            else:
                blueprint_details = get_blueprint_by_type(project_id, document_type)
                if blueprint_details:
                    response_body = blueprint_details
                else:
                    status_code = 404
                    response_body = {'message': f"Blueprint for document type '{document_type}' not found in project '{project_id}'"}

        elif operation == 'delete_blueprint':
            blueprint_arn = body.get('blueprintArn') # Changed from blueprint_id
            if not blueprint_arn:
                status_code = 400
                response_body = {'message': 'Missing required parameter: blueprintArn'}
            else:
                response_body = delete_blueprint(blueprint_arn)
        elif operation == 'update_blueprint':
            blueprint_arn = body.get('blueprintArn') # Changed from blueprint_id
            definition = body.get('definition') # Still get definition dict from body
            if not blueprint_arn or not definition:
                 status_code = 400
                 response_body = {'message': 'Missing required parameters: blueprintArn and definition'}
            else:
                 response_body = update_blueprint(blueprint_arn, definition) # Pass ARN and dict

        # Add more operations here as needed...

        else:
            status_code = 400
            response_body = {'message': f'Unsupported operation: {operation}'}

        # Prepare the response for the agent or direct invocation
        # Agent expects a specific response structure
        if 'agent' in event:
             action_response = {
                 "actionGroup": event.get("actionGroup"),
                 "apiPath": event.get("apiPath"),
                 "httpMethod": event.get("httpMethod"),
                 "httpStatusCode": status_code,
                 "responseBody": {
                     "application/json": {
                         "body": json.dumps(response_body)
                      }
                  }
              }
             final_response = {
                 'messageVersion': '1.0',
                 'response': action_response
             }
        else:
            # Standard API Gateway response
             final_response = {
                 'statusCode': status_code,
                 'headers': {
                     'Content-Type': 'application/json',
                     'Access-Control-Allow-Origin': '*' # Adjust CORS as needed
                 },
                 'body': json.dumps(response_body)
             }

        logger.info(f"Operation {operation} completed with status {status_code}. Response: {json.dumps(final_response)}")
        return final_response

    except Exception as e:
        logger.error(f"Error processing operation: {traceback.format_exc()}")
        error_response_body = {'message': f'Internal server error: {str(e)}'}
        # Agent specific error structure
        if 'agent' in event:
             action_response = {
                 "actionGroup": event.get("actionGroup"),
                 "apiPath": event.get("apiPath"),
                 "httpMethod": event.get("httpMethod"),
                 "httpStatusCode": 500,
                 "responseBody": {
                     "application/json": {
                         "body": json.dumps(error_response_body)
                      }
                  }
              }
             return {
                 'messageVersion': '1.0',
                 'response': action_response
             }
        else:
             return {
                 'statusCode': 500,
                 'headers': {
                     'Content-Type': 'application/json',
                     'Access-Control-Allow-Origin': '*' # Adjust CORS as needed
                 },
                 'body': json.dumps(error_response_body)
             }

@logger.inject_lambda_context(log_event=True)
def lambda_handler(event, context):
    """
    AWS Lambda handler function.
    
    Args:
        event (dict): Lambda event
        context (object): Lambda context
        
    Returns:
        dict: Response to the Lambda invocation
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        result = process_operation(event)
        return {
            "statusCode": 200,
            "body": result if isinstance(result, str) else json.dumps(result)
        }
    except Exception as e:
        error_message = str(e)
        stack_trace = traceback.format_exc()
        logger.error(f"Error processing request: {error_message}")
        logger.error(f"Stack trace: {stack_trace}")
        
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": error_message,
                "trace": stack_trace
            })
        } 