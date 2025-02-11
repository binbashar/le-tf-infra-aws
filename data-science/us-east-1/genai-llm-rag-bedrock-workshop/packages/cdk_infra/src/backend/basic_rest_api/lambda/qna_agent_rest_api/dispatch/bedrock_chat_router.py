# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import os
from botocore.exceptions import ClientError
from aws_lambda_powertools import Logger
from dispatch.chat_context_client import ChatContextClient
from dispatch.types.chat_context import ChatContext
from dispatch.bedrock_client import BedrockClient
from aws_lambda_powertools import Logger

logger = Logger(use_rfc3339=True)

table_name = os.getenv('SESSIONS_TABLE')
region_name = os.getenv('AWS_REGION')
agent_id = os.getenv('AGENT_ID')
agent_alias_id = os.getenv('AGENT_ALIAS_ID')
knowledge_base_id = os.getenv('KNOWLEDGE_BASE_ID')

logger.debug("DynamoDB Table Name: ", table_name)
logger.debug("AWS Region: ", region_name)
logger.debug("Agent ID: ", agent_id)
logger.debug("Agent Alias ID: ", agent_alias_id)
logger.debug("Knowledge Base ID: ", knowledge_base_id)


class BedrockChatRouter:

    def __init__(self, session_id: str, session_attributes: dict, metadata: dict):
        logger.info('Initializing BedrockChatRouter')

        self.chat_context_client = ChatContextClient(
            # Allows session persistence in DynamoDB
            table_name=table_name, region=region_name)
        self.agent_id = agent_id
        self.agent_alias_id = agent_alias_id
        self.knowledge_base_id = knowledge_base_id

        # Obtain existing ChatContext from session Id, or else generate a new session Id and a new ChatContext
        if session_id:
            self.session_id = session_id
            self.chat_context: ChatContext = self.chat_context_client.get(
                session_id)
        else:
            # Creating an empty chat context generates a new sessionId UUId.
            self.chat_context: ChatContext = ChatContext()
            self.session_id = self.chat_context.session_id
            logger.info(f'Persisting new ChatContext in DynamoDB Table with session Id {self.session_id}')
            self.chat_context_client.upsert(self.chat_context)

        if session_attributes:
            self.session_attributes = session_attributes
        else:
            self.session_attributes = None

        if metadata:
            self.metadata = metadata
            logger.info(f'Metadata filter: {self.metadata}')
        else:
            self.metadata = None

        # Initialize Amazon Bedrock Agent Runtime Client
        bedrock_client = BedrockClient(region_name)
        self.bedrock_agent_runtime_client = bedrock_client.get_bedrock_agent_runtime_client()

    def invoke_agent(self, prompt):
        """
        Sends a prompt for the Amazon Bedrock Agent to process and respond to.
        :param prompt: The prompt that you want Claude to complete.
        :return: Inference response from the model.
        """

        try:

            # Set up SessionState for the agent
            logger.info('Setting up SessionState for the agent')
            session_state: dict = {}
            if self.session_attributes:
                session_state["sessionAttributes"] = self.session_attributes
            if self.metadata:
                session_state["knowledgeBaseConfigurations"] = [
                    {
                        'knowledgeBaseId': self.knowledge_base_id,
                        'retrievalConfiguration': {
                            'vectorSearchConfiguration': {
                                'filter': self.metadata
                            }
                        }
                    }
                ]
            logger.info(f'SessionState: {session_state}')

            logger.info('Calling invoke_agent')
            response = self.bedrock_agent_runtime_client.invoke_agent(
                agentId=self.agent_id,
                agentAliasId=self.agent_alias_id,
                sessionId=self.session_id,
                inputText=prompt,
                sessionState=session_state
            )

            logger.info("Processing Agent Response")
            completion = ""
            references = []
            for event in response.get("completion"):
                chunk = event["chunk"]
                completion = completion + chunk["bytes"].decode()

                # Extract retrievedReferences from attribution
                logger.info("Extracting references")
                if "attribution" in chunk and "citations" in chunk["attribution"]:
                    for citation in chunk["attribution"]["citations"]:
                        for reference in citation.get("retrievedReferences", []):
                            reference_info = {
                                "content": reference.get("content", {}).get("text"),
                                "metadata": reference.get("metadata", {})
                            }
                            references.append(reference_info)

        except ClientError as e:
            logger.error(f"Couldn't invoke agent. {e}")
            raise

        return {
            'completion': completion,
            'references': references
        }

    def chat_with_agent(self, message: str):
        logger.info(f'Message from request is: {message}')

        logger.info('Invoking Amazon Bedrock Agent')
        response = self.invoke_agent(message)
        logger.info(f'Agent response is: {response}')

        # Keeping session history for 8 messages.
        logger.info('Updating ChatContext history')
        self.chat_context.history.extend([
            {
                'type': 'human',
                'text': message
            },
            {
                'type': 'assistant',
                'text': response['completion']
            }
        ])

        if len(self.chat_context.history) >= 8:
            self.chat_context.history = self.chat_context.history[-6:]
        logger.info(f'ChatContext history updated value: {self.chat_context.history}')

        logger.info('Updating ChatContext in DynamoDB Table')
        self.chat_context_client.upsert(self.chat_context)

        # Structure final response
        body_content = {
            "message": response["completion"],
        }
        
        # Add citations field only when metadata was provided in the request.
        if response["references"] and self.metadata:
            body_content["citations"] = response["references"]

        logger.info(f'Agent response: {body_content}')

        logger.info('Returning agent response')
        return body_content
