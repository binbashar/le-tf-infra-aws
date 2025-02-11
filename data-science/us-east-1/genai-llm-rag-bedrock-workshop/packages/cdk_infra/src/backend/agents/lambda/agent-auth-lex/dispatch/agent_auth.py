# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import boto3
import botocore
from . import lex_helper as helper
import os

logger = helper.get_logger(__name__)
region = os.environ.get('AWS_REGION')


class AgentEnabledBot():
    def __init__(self, agent_id, agent_alias_id):
        print(boto3.__version__)
        self.agent_id = agent_id
        self.agent_alias_id = agent_alias_id
        bed_session = boto3.Session()
        self.agents_runtime_client = bed_session.client(service_name="bedrock-agent-runtime",
                                                        region_name=region,
                                                        endpoint_url=f"https://bedrock-agent-runtime.{region}.amazonaws.com",
                                                        )

    def end_conversation(self, session_id, prompt):

        response = self.agents_runtime_client.invoke_agent(
            agentId=self.agent_id,
            endSession=True,
            agentAliasId=self.agent_alias_id,
            sessionId=session_id,
            inputText=prompt,
        )

        completion = ""

        for event in response.get("completion"):
            if "chunk" in event:
                chunk = event["chunk"]
                completion += chunk["bytes"].decode()

        return completion

    def ask(self, session_id, prompt):

        response = self.agents_runtime_client.invoke_agent(
            agentId=self.agent_id,
            endSession=False,
            agentAliasId=self.agent_alias_id,
            sessionId=session_id,
            inputText=prompt,
            enableTrace=False
        )
        print(response)
        completion = ""

        for event in response.get("completion"):
            print(event)
            if "chunk" in event:
                chunk = event["chunk"]
                completion += chunk["bytes"].decode()

        return completion
