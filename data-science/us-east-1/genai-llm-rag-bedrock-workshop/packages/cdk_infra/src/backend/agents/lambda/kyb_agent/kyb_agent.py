# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json
import boto3
import os
import uuid
import datetime
from botocore.exceptions import ClientError
from aws_lambda_powertools import Logger

# Initialize logger
logger = Logger()

# Custom JSON encoder to handle datetime objects
class DateTimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (datetime.datetime, datetime.date)):
            return obj.isoformat()
        return super(DateTimeEncoder, self).default(obj)

# Environment variables
REGION = os.environ.get('REGION')
AGENT_NAME_PREFIX = os.environ.get('AGENT_NAME_PREFIX')
AGENT_ALIAS_ID = os.environ.get('AGENT_ALIAS_ID', 'DRAFT')
INPUT_BUCKET = os.environ.get('INPUT_BUCKET')
OUTPUT_BUCKET = os.environ.get('OUTPUT_BUCKET')

# Initialize AWS clients
bedrock_agent_runtime = boto3.client('bedrock-agent-runtime', region_name=REGION)
bedrock_agent = boto3.client('bedrock-agent', region_name=REGION)
s3 = boto3.client('s3', region_name=REGION)

# Agent ID cache
_agent_id = None
_agent_alias_id = None

def find_agent_id():
    """
    Find the Agent ID by listing agents and looking for one with the specified name prefix.
    Falls back to looking for any document processing agent.
    
    Returns:
        The Agent ID string
        
    Raises:
        ValueError if no suitable agent is found or if the agent has no usable aliases
    """
    global _agent_id, _agent_alias_id
    
    # Return cached values if available
    if _agent_id and _agent_alias_id:
        return _agent_id
    
    try:
        # List all agents and look for one with the specified name prefix
        response = bedrock_agent.list_agents()
        logger.info(f"Found agents: {json.dumps([a.get('agentName') for a in response.get('agentSummaries', [])], cls=DateTimeEncoder)}")
        
        found_agent_id = None
        found_agent_name = None
        
        # First look for exact prefix match
        for agent in response.get('agentSummaries', []):
            agent_id = agent.get('agentId')
            agent_name = agent.get('agentName', '')
                
            if AGENT_NAME_PREFIX and agent_name.startswith(AGENT_NAME_PREFIX):
                logger.info(f"Found exact prefix match: {agent_name} ({agent_id})")
                found_agent_id = agent_id
                found_agent_name = agent_name
                break
        
        # If no exact match, look for DocumentProcessingAgent
        if not found_agent_id:
            for agent in response.get('agentSummaries', []):
                agent_id = agent.get('agentId')
                agent_name = agent.get('agentName', '')
                
                if 'DocumentProcessingAgent' in agent_name:
                    logger.info(f"Found DocumentProcessingAgent: {agent_name} ({agent_id})")
                    found_agent_id = agent_id
                    found_agent_name = agent_name
                    break
        
        # If we found an agent, get its aliases
        if found_agent_id:
            alias_response = bedrock_agent.list_agent_aliases(agentId=found_agent_id)
            aliases = alias_response.get('agentAliasSummaries', [])

            if aliases:
                # First look for DRAFT alias
                for alias in aliases:
                    alias_id = alias.get('agentAliasId')
                    alias_name = alias.get('agentAliasName', '')
                    
                    if alias_name == 'DRAFT':
                        _agent_id = found_agent_id
                        _agent_alias_id = alias_id
                        logger.info(f"Using agent {found_agent_name} ({found_agent_id}) with DRAFT alias")
                        return _agent_id
                
                # If no DRAFT alias, use the first one
                _agent_id = found_agent_id
                _agent_alias_id = aliases[0].get('agentAliasId')
                logger.info(f"Using agent {found_agent_name} ({found_agent_id}) with first available alias {_agent_alias_id}")
                return _agent_id
        else:
            raise ValueError(f"Agent {found_agent_name} ({found_agent_id}) has no aliases")
        
        raise ValueError(f"No suitable Bedrock Agent found with name prefix: {AGENT_NAME_PREFIX} or containing 'DocumentProcessingAgent'")
            
    except ClientError as e:
        error_message = str(e)
        logger.error(f"Error finding agent: {error_message}")
        raise ValueError(f"Error finding Bedrock Agent: {error_message}")

def invoke_agent(prompt, session_id):
    """
    Invoke the Bedrock Agent with a prompt.
    
    Args:
        prompt: The prompt to send to the agent
        session_id: The session ID for the conversation
        
    Returns:
        The agent's response
    """
    try:
        # Find agent ID if not already cached
        agent_id = find_agent_id()
        
        # Use the cached alias ID
        global _agent_alias_id
        if not _agent_alias_id:
            raise ValueError("No valid agent alias found")
            
        logger.info(f"Invoking agent {agent_id} with alias {_agent_alias_id}")
            
        response = bedrock_agent_runtime.invoke_agent(
            agentId=agent_id,
            agentAliasId=_agent_alias_id,
            sessionId=session_id,
            inputText=prompt
        )
        
        completion = ""
        for event in response.get("completion", []):
            chunk = event.get("chunk", {})
            completion += chunk.get("bytes", b"").decode()
            
        return completion
    except ClientError as e:
        error_message = str(e)
        logger.error(f"Error invoking agent: {error_message}")
        raise ValueError(f"Error invoking Bedrock Agent: {error_message}")

def lambda_handler(event, context):
    """
    Lambda handler for the KYB Agent API.
    
    Args:
        event: The Lambda event
        context: The Lambda context
        
    Returns:
        API Gateway response with CORS headers
    """
    try:
        logger.info(f"Received event: {json.dumps(event, cls=DateTimeEncoder)}")
        
        # Define CORS headers to include in all responses
        cors_headers = {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': 'http://localhost:5173',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        }
        
        # Handle preflight CORS request
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': cors_headers,
                'body': '{}'
            }
        
        # Parse the request body
        body = {}
        if event.get('body'):
            if isinstance(event['body'], str):
                body = json.loads(event['body'])
            else:
                body = event['body']
        
        s3_key = body.get('s3Key')
        document_type = body.get('documentType')
        filename = body.get('filename')
        
        if not all([s3_key, document_type]):
            logger.error(f"Missing required parameters: s3Key={s3_key}, documentType={document_type}")
            return {
                'statusCode': 400,
                'headers': cors_headers,
                'body': json.dumps({
                    'message': 'Missing required parameters: s3Key and documentType are required'
                }, cls=DateTimeEncoder)
            }
        
        # Verify the document exists in S3
        try:
            s3.head_object(Bucket=INPUT_BUCKET, Key=s3_key)
            logger.info(f"Document exists at s3://{INPUT_BUCKET}/{s3_key}")
        except ClientError:
            logger.error(f"Document not found at s3://{INPUT_BUCKET}/{s3_key}")
            return {
                'statusCode': 404,
                'headers': cors_headers,
                'body': json.dumps({
                    'message': 'Document not found in S3'
                }, cls=DateTimeEncoder)
            }
        
        # Create a new session ID for this KYB process
        session_id = str(uuid.uuid4())
        
        # Create a comprehensive prompt for the Bedrock Agent
        agent_prompt = f"""
        I need to process a '{document_type}' document for KYB (Know Your Business) purposes.
        The document is stored at s3://{INPUT_BUCKET}/{s3_key}
        The filename is {filename}
        
        Please complete the following tasks:
        
        1. Use your 'blueprint-management' action to ensure there's a blueprint for {document_type} documents
        2. Use your 'kyb-processing' action to extract relevant information from the document
        3. Use your 'kyb-validation' action to validate the extracted information
        4. Provide a summary of the extracted information and any issues found
        
        Return the results in JSON format that includes:
        - The extracted fields with their values
        - Confidence scores for each field
        - Any validation issues identified
        """
        
        # Invoke the Bedrock Agent to do the actual work
        agent_response = invoke_agent(agent_prompt, session_id)
        logger.info(f"Agent response received with {len(agent_response)} characters")
        
        # Parse the agent response to extract JSON results
        # Look for JSON content in the agent response
        result = {
            'status': 'success',
            'documentType': document_type,
            'agent_response': agent_response
        }
        
        # Try to extract structured data from the agent response
        try:
            # Look for JSON data in the response, which might be surrounded by text
            json_start = agent_response.find('{')
            json_end = agent_response.rfind('}')
            
            if json_start >= 0 and json_end > json_start:
                json_str = agent_response[json_start:json_end+1]
                parsed_data = json.loads(json_str)
                result['parsed_data'] = parsed_data
                
                # Extract confidence scores if available
                if 'confidence' in parsed_data:
                    result['confidence'] = parsed_data['confidence']
                elif 'confidence_scores' in parsed_data:
                    result['confidence'] = parsed_data['confidence_scores']
        except Exception as parse_error:
            logger.warning(f"Could not extract JSON from agent response: {str(parse_error)}")
            
            # Return the results
            return {
                'statusCode': 200,
                'headers': cors_headers,
                'body': json.dumps(result, cls=DateTimeEncoder)
            }
        
    except Exception as e:
        logger.error(f"Error in KYB Agent API: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers,
            'body': json.dumps({
                'message': f"Error processing document: {str(e)}"
            }, cls=DateTimeEncoder)
        } 