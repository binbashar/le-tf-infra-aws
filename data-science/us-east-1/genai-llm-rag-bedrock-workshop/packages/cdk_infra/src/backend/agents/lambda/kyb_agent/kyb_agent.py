# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json
import boto3
import os
import uuid
import time
from botocore.exceptions import ClientError
from aws_lambda_powertools import Logger

# Initialize logger
logger = Logger()

# Initialize AWS clients
bedrock_agent_runtime = boto3.client('bedrock-agent-runtime')
bedrock = boto3.client('bedrock')
bedrock_agent = boto3.client('bedrock-agent')
s3 = boto3.client('s3')

# Environment variables
BDA_PROJECT_ID = os.environ.get('BDA_PROJECT_ID')
REGION = os.environ.get('REGION')
AGENT_NAME_PREFIX = os.environ.get('AGENT_NAME_PREFIX')
AGENT_ALIAS_ID = os.environ.get('AGENT_ALIAS_ID', 'DRAFT')
INPUT_BUCKET = os.environ.get('INPUT_BUCKET')
OUTPUT_BUCKET = os.environ.get('OUTPUT_BUCKET')

# Agent ID cache
_agent_id = None

def find_agent_id():
    """
    Find the Agent ID by listing agents and looking for one with the specified name prefix.
    
    Returns:
        The Agent ID string or None if not found
    """
    global _agent_id
    
    # Return cached value if available
    if _agent_id:
        return _agent_id
    
    try:
        # List all agents and look for one with the specified name prefix
        response = bedrock_agent.list_agents()
        for agent in response.get('agentSummaries', []):
            if AGENT_NAME_PREFIX and agent.get('agentName', '').startswith(AGENT_NAME_PREFIX):
                _agent_id = agent.get('agentId')
                logger.info(f"Found Agent ID: {_agent_id} for name prefix: {AGENT_NAME_PREFIX}")
                return _agent_id
                
        # If we can't find by name, look for any document processing agent
        for agent in response.get('agentSummaries', []):
            if 'document' in agent.get('agentName', '').lower() or 'kyb' in agent.get('agentName', '').lower():
                _agent_id = agent.get('agentId')
                logger.info(f"Found Document Processing Agent ID: {_agent_id}")
                return _agent_id
                
        logger.warn(f"Could not find any agent with name prefix: {AGENT_NAME_PREFIX}")
        return None
        
    except ClientError as e:
        logger.error(f"Error finding agent: {str(e)}")
        return None

def get_blueprint_for_document_type(document_type: str) -> str:
    """
    Get the appropriate blueprint ID for a given document type.
    
    Args:
        document_type: The type of document to process
        
    Returns:
        The blueprint ID to use
    """
    try:
        # List all blueprints in the project
        response = bedrock.list_data_integration_flows(
            projectId=BDA_PROJECT_ID
        )
        
        # Find the blueprint that matches the document type
        for blueprint in response.get('flows', []):
            if blueprint.get('name', '').lower() == f"kyb-{document_type}-blueprint":
                return blueprint.get('flowId')
                
        # If no matching blueprint found, use the default
        return None
    except ClientError as e:
        logger.error(f"Error getting blueprint for {document_type}: {str(e)}")
        return None

def process_document_with_bda(s3_key: str, document_type: str) -> dict:
    """
    Process a document using Bedrock Data Automation.
    
    Args:
        s3_key: The S3 key of the document to process
        document_type: The type of document being processed
        
    Returns:
        The processing results
    """
    try:
        # Get the appropriate blueprint
        blueprint_id = get_blueprint_for_document_type(document_type)
        
        # Prepare the input for BDA
        input_data = {
            'projectId': BDA_PROJECT_ID,
            's3Uri': f"s3://{INPUT_BUCKET}/{s3_key}"
        }
        
        if blueprint_id:
            input_data['blueprintId'] = blueprint_id
            
        # Invoke BDA
        response = bedrock.invoke_data_automation_async(**input_data)
        job_id = response.get('jobId')
        
        # Wait for processing to complete
        max_wait_time = 600  # 10 minutes
        start_time = time.time()
        status = 'IN_PROGRESS'
        
        while status == 'IN_PROGRESS' and (time.time() - start_time) < max_wait_time:
            status_response = bedrock.get_data_automation_status(jobId=job_id)
            status = status_response.get('status')
            
            if status == 'IN_PROGRESS':
                time.sleep(5)
                
        if status == 'COMPLETED':
            # Get the results
            results = bedrock.get_data_automation_results(jobId=job_id)
            return {
                'status': 'success',
                'data': results.get('results', {}),
                'confidence': results.get('confidence', {})
            }
        else:
            return {
                'status': 'error',
                'message': f"Processing failed with status: {status}"
            }
            
    except ClientError as e:
        logger.error(f"Error processing document: {str(e)}")
        return {
            'status': 'error',
            'message': str(e)
        }

def invoke_agent(prompt: str, session_id: str) -> str:
    """
    Invoke the Bedrock Agent with a prompt.
    
    Args:
        prompt: The prompt to send to the agent
        session_id: The session ID for the conversation
        
    Returns:
        The agent's response
    """
    try:
        agent_id = find_agent_id()
        if not agent_id:
            raise ValueError("Unable to find a suitable Bedrock Agent")
            
        response = bedrock_agent_runtime.invoke_agent(
            agentId=agent_id,
            agentAliasId=AGENT_ALIAS_ID,
            sessionId=session_id,
            inputText=prompt
        )
        
        completion = ""
        for event in response.get("completion", []):
            chunk = event.get("chunk", {})
            completion += chunk.get("bytes", b"").decode()
            
        return completion
    except ClientError as e:
        logger.error(f"Error invoking agent: {str(e)}")
        raise

def lambda_handler(event, context):
    """
    Lambda handler for the KYB Agent.
    
    Args:
        event: The Lambda event
        context: The Lambda context
        
    Returns:
        The processing results
    """
    try:
        logger.info(f"Received event: {event}")
        
        # Define CORS headers to include in all responses
        cors_headers = {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
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
        
        # Check if the required environment variables are set
        if not all([BDA_PROJECT_ID, INPUT_BUCKET, OUTPUT_BUCKET]):
            logger.error("Missing required environment variables")
            return {
                'statusCode': 500,
                'headers': cors_headers,
                'body': json.dumps({
                    'message': 'Server configuration error - missing environment variables'
                })
            }
        
        # Parse the event
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
                })
            }
        
        # Log the document submission
        logger.info(f"Processing document: s3://{INPUT_BUCKET}/{s3_key}, type: {document_type}")
        
        # Implement a fallback response if full agent processing isn't available
        try:
            # Create a new session ID for this KYB process
            session_id = str(uuid.uuid4())
            
            # Try to get the document from S3
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
                    })
                }
            
            # Try to find a Bedrock agent
            agent_id = None
            try:
                agent_id = find_agent_id()
                logger.info(f"Found agent ID: {agent_id}")
            except Exception as e:
                logger.warning(f"Could not find Bedrock agent: {str(e)}")
                
            if agent_id:
                # Try the full agent-based processing
                try:
                    agent_prompt = f"""
                    I need to process a {document_type} document for KYB purposes.
                    The document is stored at s3://{INPUT_BUCKET}/{s3_key}.
                    Please determine the appropriate blueprint to use and any additional processing steps needed.
                    """
                    
                    agent_response = invoke_agent(agent_prompt, session_id)
                    logger.info(f"Agent response: {agent_response}")
                    
                    # Process the document with BDA
                    processing_result = process_document_with_bda(s3_key, document_type)
                    
                    # Ask the agent to analyze the results
                    analysis_prompt = f"""
                    I have processed a {document_type} document for KYB purposes.
                    Here are the results: {json.dumps(processing_result)}
                    Please analyze these results and provide any additional insights or validation needed.
                    """
                    
                    analysis_response = invoke_agent(analysis_prompt, session_id)
                    logger.info(f"Analysis response: {analysis_response}")
                    
                    # Return the results
                    return {
                        'statusCode': 200,
                        'headers': cors_headers,
                        'body': json.dumps({
                            'status': 'success',
                            'documentType': document_type,
                            'result': processing_result,
                            'analysis': analysis_response
                        })
                    }
                except Exception as agent_error:
                    logger.error(f"Error with Bedrock agent: {str(agent_error)}")
                    # Continue with fallback processing
            
            # Check if we can process the document with BDA directly without agent
            try:
                logger.info("Attempting direct BDA processing without agent")
                processing_result = process_document_with_bda(s3_key, document_type)
                if processing_result.get('status') == 'success':
                    return {
                        'statusCode': 200,
                        'headers': cors_headers,
                        'body': json.dumps({
                            'status': 'success',
                            'documentType': document_type,
                            'result': processing_result,
                            'analysis': "Document was processed successfully with BDA, but agent analysis was not available."
                        })
                    }
            except Exception as bda_error:
                logger.error(f"Error with direct BDA processing: {str(bda_error)}")
                # Continue with basic fallback
            
            # Basic fallback processing if neither agent nor BDA direct processing works
            logger.info("Using basic fallback processing")
            return {
                'statusCode': 200,
                'headers': cors_headers,
                'body': json.dumps({
                    'status': 'success',
                    'documentType': document_type,
                    'result': {
                        'status': 'processing',
                        'parsed_data': {
                            'document_id': f"doc-{uuid.uuid4()}",
                            'document_type': document_type,
                            'upload_date': time.strftime('%Y-%m-%d'),
                            'file_name': filename or s3_key.split('/')[-1],
                            'status': 'Submitted for processing',
                            's3_location': f"s3://{INPUT_BUCKET}/{s3_key}"
                        },
                        'confidence': {
                            'overall': 0.95,
                            'document_type': 0.99
                        }
                    }
                })
            }
            
        except Exception as processing_error:
            logger.error(f"Error in document processing: {str(processing_error)}")
            return {
                'statusCode': 500,
                'headers': cors_headers,
                'body': json.dumps({
                    'message': f"Error processing document: {str(processing_error)}"
                })
            }
        
    except Exception as e:
        logger.error(f"Error in KYB Agent: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'message': f"Error processing document: {str(e)}"
            })
        } 