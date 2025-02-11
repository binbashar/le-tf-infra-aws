# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json
import boto3
from os import environ
from botocore.exceptions import ClientError
from aws_lambda_powertools import Logger

logger = Logger()

@logger.inject_lambda_context
def lambda_handler(event, context):
    logger.info(f"Received event: {event}")
    
    request = json.loads(event['body'])

    # Auth Parameter Info
    # param1 = event['requestContext']['authorizer']['param1']
    # param2 = event['requestContext']['authorizer']['param2']
    # print(f'Parameter1 : {param1}, Parameter2 : {param2}')

    if request is None:
        return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                    },
                'body': json.dumps({
                        "response": "No body found",
                        "SessionId": ""
                        }),
                "isBase64Encoded": False
                }
             
    sessionId: str = request['sessionId']

    return summarize_chat(session_id=sessionId)
		

def summarize_chat(session_id):
    """
    Retrieves the chat history from DynamoDB using the given session ID and 
    requests a summary from the Haiku LLM model.

    Parameters:
    session_id (str): The ID of the session to retrieve the chat history for.

    Returns:
    dict: A response payload containing the summary of the chat history,
          suitable for returning from a Lambda function.

    If there is an error invoking the LLM model, the response payload will contain 
    the error details with a 500 status code.
    """
    session_table = environ.get("SESSION_TABLE")
    
    # Retrive chat history    
    dynamodb = boto3.resource("dynamodb").Table(session_table)
    response = dynamodb.get_item(Key={"sessionId": session_id}, AttributesToGet=["history"])
    history = response.get("Item", {}).get("history", {})
    history_string = str(history)
    logger.info(f"Retrieved history: {history_string}")

    # Example prompt to request summary generation
    prompt = f"""
            Here is the chat history. Please summarize it in a simple and short manner. 
            <history>{history_string}</history>
            """
    
    # Summarize the chat history using LLM
    brt = boto3.client(service_name='bedrock-runtime')

    # Note: Use the correct invocation format for each model
    # In this example, Nova Lite is in use
    MODEL_ID = "us.amazon.nova-lite-v1:0"
    
    # Define your system prompt(s).
    system_list = [
        {
            "text": "Summarize the chat history between the user and chatbot for the live agent."
        }
    ]

    # Define one or more messages using the "user" and "assistant" roles.
    message_list = [{"role": "user", "content": [{"text": prompt}]}]

    body = json.dumps({
        "schemaVersion": "messages-v1",
        "messages": message_list,
        "system": system_list,
    })
    
    try:
        # Invoke the model
        logger.info("Invoking model...")
        response = brt.invoke_model(body=body, modelId=MODEL_ID)
        response_body = json.loads(response.get('body').read())
        print("Model response:", response_body)
        summary = response_body['output']['message']['content'][0]['text']
        summary = summary.replace('\n', ' ').replace('\r', ' ')
        
        # Store summary in DynamoDB
        dynamodb.update_item(Key={"sessionId": session_id}, AttributeUpdates={"summary": {"Value": summary}})

    except ClientError as e:
        logger.exception(f"Client Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            "summary": summary,
        }),
        "isBase64Encoded": False
    }