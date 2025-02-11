# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

from dispatch.lex_helper import *
from dispatch.agent_auth_bot import LexV2AgentAuthBotDispatcher
import logging

logger = get_logger(__name__)
logger.setLevel(logging.INFO)


def dispatch_lexv2(request):
    lexv2_dispatcher = LexV2AgentAuthBotDispatcher(request)

    return lexv2_dispatcher.dispatch_intent()


def lambda_handler(event, context):
    print(event)
    if 'sessionState' in event:
        if 'intent' in event['sessionState']:
            if 'name' in event['sessionState']['intent']:
                #only implementing Fallback but can add other intents here to take action on
                if event['sessionState']['intent']['name'] == 'FallbackIntent':
                    return dispatch_lexv2(event)