# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json
import boto3
import os
import mailparser
from botocore.exceptions import ClientError
import uuid
import asyncio


# Initialize the SES and Bedrock clients
ses_client = boto3.client('ses')
s3 = boto3.client('s3')
bedrock_client = boto3.client('bedrock-agent-runtime')

# Read AGENT_ARN env variable
AGENT_ARN = os.environ['AGENT_ARN']
AGENT_ALIAS_ID = os.environ['AGENT_ALIAS_ID'] if os.environ['AGENT_ALIAS_ID'] != "" else "DRAFT"
AGENT_ID = os.environ['AGENT_ID']

# Async call to Invoke Agent
async def async_invoke_agent(prompt, session_id):
        response = bedrock_client.invoke_agent(
            agentId=AGENT_ID,
            agentAliasId=AGENT_ALIAS_ID,
            sessionId=session_id,
            inputText=prompt,
        )

        completion = ""

        for event in response.get("completion"):
            chunk = event["chunk"]
            completion += chunk["bytes"].decode()

        return completion


def lambda_handler(event, context):

    print('AGENT_ARN: ', AGENT_ARN)
    print('AGENT_ALIAS_ID: ', AGENT_ALIAS_ID)
    print('AGENT_ID: ', AGENT_ID)
    print('Event: ', event)

    # Get the bucket name and file key from the event
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    file_key = event['Records'][0]['s3']['object']['key']
    print('Bucket Name: ', bucket_name)
    print('File Key: ', file_key)   

    # Read email
    # Check if the file has the .msg extension
    if (file_key.endswith('.msg') or file_key.endswith('.eml')):
        print('File has .msg extension')
        try:
            # Download the email file from S3
            print('Downloading email file from S3...')
            response = s3.get_object(Bucket=bucket_name, Key=file_key)
            email_data = response['Body'].read()
            print('Email Data: ', email_data)

            # Parse the email using mail-parser
            parsed_email = mailparser.parse_from_bytes(email_data)
            print('Parsed Email: ', parsed_email)

            # Access email properties
            print('Accessing email properties')
            subject = parsed_email.subject
            sender = parsed_email.from_[0][1]
            recipients = [recipient[1] for recipient in parsed_email.to]
            body = parsed_email.body
            message = parsed_email.message_as_string

            # Process the email data as needed
            print(f"Subject: {subject}")
            print(f"From: {sender}")
            print(f"To: {', '.join(recipients)}")
            # print(f"Body: {body}")
            parts = body.split('--- mail_boundary ---')
            content_before_delimiter = parts[0].strip()
            print(f"Content before delimiter: {content_before_delimiter}")

            # Call the Amazon Bedrock Agent
            # print('Calling Bedrock Agent...')
            # response = bedrock_client.invoke_agent(
            #     agentAliasId=AGENT_ALIAS_ID,
            #     agentId=AGENT_ID,
            #     enableTrace=False,
            #     endSession=True,
            #     inputText=content_before_delimiter,
            #     sessionId=str(uuid.uuid4())
            # )

            print('Calling Bedrock Agent...')
            session_id = str(uuid.uuid4())
            response = asyncio.run(async_invoke_agent(content_before_delimiter, session_id))
            print('Bedrock Agent Response: ', response)

            # Prepare the email response
            print('Preparing email response...')
            output_sender = 'success@simulator.amazonses.com'
            output_recipient = sender
            output_subject = 'Response from Bedrock Agent'
            output_body = f'The output from the Bedrock Agent is: {response}'

            print('Output: ', output_body)
            print('Email Response: ', output_subject, output_body)
            print('Sender: ', output_sender)
            print('Recipient: ', output_recipient)

            # Send the email response using SES
            ses_client.send_email(
                Source=sender,
                Destination={
                    'ToAddresses': [output_recipient]
                },
                Message={
                    'Subject': {
                        'Data': output_subject
                    },
                    'Body': {
                        'Text': {
                            'Data': output_body
                        }
                    }
                }
            )
            print('Email response sent.')

            return {
                'statusCode': 200,
                'body': json.dumps('Email response sent successfully')
            }

        except ClientError as e:
            print(f"Error: {e.response['Error']['Message']}")
    else:
        print(
            f"Skipping file {file_key} as it doesn't have the .msg extension.")
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid email format')
        }

    
