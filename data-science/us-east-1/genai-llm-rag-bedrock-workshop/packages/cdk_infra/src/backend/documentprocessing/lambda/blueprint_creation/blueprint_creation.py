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

# Initialize AWS clients
bedrock = boto3.client('bedrock')

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
        response = bedrock.create_data_integration_project(
            name=project_name,
            description=description
        )
        logger.info(f"Created project: {project_name} with ID: {response.get('projectId')}")
        return response
    except Exception as e:
        logger.error(f"Error creating project '{project_name}': {str(e)}")
        raise

def create_blueprint(project_id, blueprint_name, description, definition):
    """
    Create a single blueprint in Bedrock Data Integration.
    
    Args:
        project_id (str): Project ID
        blueprint_name (str): Blueprint name
        description (str): Blueprint description
        definition (dict): Blueprint definition
    
    Returns:
        dict: Created blueprint details
    """
    try:
        response = bedrock.create_data_integration_flow(
            name=blueprint_name,
            projectId=project_id,
            description=description,
            definition=definition
        )
        logger.info(f"Created blueprint: {blueprint_name} with ID: {response.get('flowId')}")
        return response
    except Exception as e:
        logger.error(f"Error creating blueprint '{blueprint_name}': {str(e)}")
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
            project_id = project_response.get('projectId')
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
            # Extract blueprint details from configuration
            blueprint_name = blueprint_data.get('name', f"kyb-{blueprint_type}-blueprint")
            blueprint_description = blueprint_data.get('description', f"Blueprint for {blueprint_type} KYB document processing")
            blueprint_fields = blueprint_data.get('fields', [])
            
            # Format the definition to match Bedrock Data Integration expectations
            blueprint_definition = {
                "fields": blueprint_fields
            }
            
            # Create the blueprint
            response = create_blueprint(
                project_id=project_id,
                blueprint_name=blueprint_name,
                description=blueprint_description,
                definition=blueprint_definition
            )
            
            # Record the created blueprint
            created_blueprints.append({
                "type": blueprint_type,
                "id": response.get('flowId'),
                "name": blueprint_name,
                "status": "created"
            })
            
        except Exception as e:
            logger.error(f"Failed to create blueprint for {blueprint_type}: {str(e)}")
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
        project_id (str, optional): Project ID to filter blueprints
        
    Returns:
        dict: List of blueprints
    """
    try:
        if project_id:
            response = bedrock.list_data_integration_flows(
                projectId=project_id
            )
        else:
            response = bedrock.list_data_integration_flows()
        return response
    except Exception as e:
        logger.error(f"Error listing blueprints: {str(e)}")
        raise

def get_blueprint(blueprint_id):
    """
    Get details of a specific blueprint.
    
    Args:
        blueprint_id (str): Blueprint ID
        
    Returns:
        dict: Blueprint details
    """
    try:
        response = bedrock.get_data_integration_flow(
            flowId=blueprint_id
        )
        return response
    except Exception as e:
        logger.error(f"Error getting blueprint {blueprint_id}: {str(e)}")
        raise

def delete_blueprint(blueprint_id):
    """
    Delete a blueprint.
    
    Args:
        blueprint_id (str): Blueprint ID to delete
        
    Returns:
        dict: Deletion response
    """
    try:
        response = bedrock.delete_data_integration_flow(
            flowId=blueprint_id
        )
        return response
    except Exception as e:
        logger.error(f"Error deleting blueprint {blueprint_id}: {str(e)}")
        raise

def update_blueprint(blueprint_id, definition):
    """
    Update a blueprint's definition.
    
    Args:
        blueprint_id (str): Blueprint ID to update
        definition (dict): New blueprint definition
        
    Returns:
        dict: Update response
    """
    try:
        response = bedrock.update_data_integration_flow(
            flowId=blueprint_id,
            definition=definition
        )
        return response
    except Exception as e:
        logger.error(f"Error updating blueprint {blueprint_id}: {str(e)}")
        raise

def process_operation(event):
    """
    Process an operation based on the event content.
    
    Args:
        event (dict): Lambda event
        
    Returns:
        dict: Operation result
    """
    operation = event.get('operation', '').lower()
    
    if operation == 'create_blueprints':
        project_id = event.get('project_id')
        project_name = event.get('project_name')
        project_description = event.get('project_description')
        
        if project_id:
            return create_kyb_blueprints(project_id)
        elif project_name:
            project_response = create_project(project_name, project_description)
            project_id = project_response.get('projectId')
            return create_kyb_blueprints(project_id)
        else:
            return create_kyb_blueprints()
    
    elif operation == 'list_blueprints':
        project_id = event.get('project_id')
        return list_blueprints(project_id)
    
    elif operation == 'get_blueprint':
        blueprint_id = event.get('blueprint_id')
        if not blueprint_id:
            return {"error": "Missing blueprint_id parameter"}
        return get_blueprint(blueprint_id)
    
    elif operation == 'delete_blueprint':
        blueprint_id = event.get('blueprint_id')
        if not blueprint_id:
            return {"error": "Missing blueprint_id parameter"}
        return delete_blueprint(blueprint_id)
    
    elif operation == 'update_blueprint':
        blueprint_id = event.get('blueprint_id')
        definition = event.get('definition')
        if not blueprint_id or not definition:
            return {"error": "Missing blueprint_id or definition parameters"}
        return update_blueprint(blueprint_id, definition)
    
    elif operation == 'detect_document_type':
        document_data = event.get('document_data')
        if not document_data:
            return {"error": "Missing document_data parameter"}
        document_type = detect_document_type(document_data)
        return {"document_type": document_type}
    
    elif operation == 'get_blueprint_for_document':
        document_type = event.get('document_type')
        if not document_type:
            document_data = event.get('document_data')
            if not document_data:
                return {"error": "Missing document_type or document_data parameter"}
            document_type = detect_document_type(document_data)
        
        blueprint_def = get_blueprint_for_document_type(document_type)
        return {
            "document_type": document_type,
            "blueprint": blueprint_def
        }
    
    else:
        return {"error": f"Unsupported operation: {operation}"}

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
        # Check if detail exists (EventBridge format)
        if 'detail' in event:
            event = event.get('detail', {})
            
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