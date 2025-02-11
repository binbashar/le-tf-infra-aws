# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import boto3
from botocore.client import Config

class BedrockClient:

    def __init__(self, region_name: str):        
        self.region = region_name        
        self.session = boto3.Session(region_name=region_name)
    
    # More or less a singleton so it doesn't get instantiated over and over again.
    def get_bedrock_runtime_client(self): 
        client = self.session.client('bedrock-runtime')
        return client

    def get_bedrock_agent_runtime_client(self):
        bedrock_config = Config(connect_timeout=120, read_timeout=120, retries={'max_attempts': 0})
        bedrock_agent_client = self.session.client("bedrock-agent-runtime", config=bedrock_config, region_name=self.region)
        return bedrock_agent_client

