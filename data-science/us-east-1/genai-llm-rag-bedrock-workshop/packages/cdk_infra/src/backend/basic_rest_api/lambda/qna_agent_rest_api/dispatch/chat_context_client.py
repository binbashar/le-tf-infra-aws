# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

from dispatch.types.chat_context import ChatContext
import boto3

class ChatContextError(Exception):
    """Base class for chat context exceptions."""
    pass

class InvalidSessionId(ChatContextError):
    """Raised when the provided session Id is invalid or does not exists."""
    pass

class UpdateException(ChatContextError):
    """Raised when the provided session Id is invalid or does not exists."""
    pass


class ChatContextClient:
    
    def __init__(self, table_name:str, region:str):
        session = boto3.Session(region_name=region)
        self.dynamodb = session.resource('dynamodb', region_name=region)
        self.table_name = table_name

    def get(self, session_id: str) -> ChatContext:
        table = self.dynamodb.Table(self.table_name)
        response: dict  = table.get_item(Key={"sessionId": session_id}) or None
        if not response or 'Item' not in response: raise InvalidSessionId(f'Session Id {session_id} does not exist')
        return ChatContext.from_dict(response['Item'])
     
    def upsert(self, chat_context: ChatContext):
        table = self.dynamodb.Table(self.table_name)
        try:      
            table.put_item(Item=chat_context.to_dict())
        except Exception as e:
            raise UpdateException(f'Error updating chat context: {e}')