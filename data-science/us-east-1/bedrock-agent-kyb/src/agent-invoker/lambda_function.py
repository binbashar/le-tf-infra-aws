import json
import os
import boto3
from uuid import uuid4

AGENT_ID = os.environ['AGENT_ID']
AGENT_ALIAS_ID = os.environ['AGENT_ALIAS_ID']

bedrock_agent_runtime = boto3.client('bedrock-agent-runtime')

def lambda_handler(event, context):
    if isinstance(event.get("body"), str):
        body = json.loads(event["body"])
    else:
        body = event.get("body", {})

    customer_id = body.get('customer_id', '').strip()

    if not customer_id:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'status': 'error',
                'message': 'customer_id is required'
            })
        }

    session_id = str(uuid4())

    response = bedrock_agent_runtime.invoke_agent(
        agentId=AGENT_ID,
        agentAliasId=AGENT_ALIAS_ID,
        sessionId=session_id,
        inputText=f'Please retrieve and process documents for customer: {customer_id}',
        sessionState={
            'sessionAttributes': {
                'customer_id': customer_id
            }
        }
    )

    result = process_agent_response(response)

    return {
        'statusCode': 200,
        'body': json.dumps({
            'status': 'success',
            'session_id': session_id,
            'agent_id': AGENT_ID,
            'customer_id': customer_id,
            'message': 'Agent invocation initiated',
            'agent_response': result
        })
    }

def process_agent_response(response):
    completion = response.get('completion', [])
    chunks = []

    for event in completion:
        if 'chunk' in event:
            chunk = event['chunk']
            if 'bytes' in chunk:
                chunks.append(chunk['bytes'].decode('utf-8'))

    return ''.join(chunks)
