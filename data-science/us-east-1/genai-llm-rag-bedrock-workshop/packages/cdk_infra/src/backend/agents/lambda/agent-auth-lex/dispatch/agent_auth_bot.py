# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

from . import lex_helper as helper
from . import agent_auth as agent_enabled_bot
import os


logger = helper.get_logger(__name__)


class LexV2AgentAuthBotDispatcher:

    def __init__(self, intent_request):
        print(intent_request)
        # See lex bot input format to lambda https://docs.aws.amazon.com/lex/latest/dg/lambda-input-response-format.html
        self.intent_request = intent_request
        self.localeId = self.intent_request['bot']['localeId']
        self.input_transcript = self.intent_request['inputTranscript']  # user input
        self.session_attributes = helper.get_session_attributes(
            self.intent_request)
        self.fulfillment_state = "Fulfilled"  # Always fulfilled for now
        self.text = ""  # response from endpoint
        self.message = {'contentType': 'PlainText', 'content': self.text}
        self.session_id = self.intent_request.get('sessionId')  # will tie to Agent_Session_ID
        self.response = None

    def dispatch_intent(self):
        auth_chat_bot = agent_enabled_bot.AgentEnabledBot(os.environ['AGENT_ID'], os.environ['AGENT_ALIAS'])

        agent_chat_bot_response = auth_chat_bot.ask(self.session_id, self.input_transcript)
        self.message = {
            'contentType': 'PlainText',
            'content': agent_chat_bot_response
        }

        self.response = helper.close(
            self.intent_request,
            self.session_attributes,
            self.fulfillment_state,
            self.message
        )

        return self.response
