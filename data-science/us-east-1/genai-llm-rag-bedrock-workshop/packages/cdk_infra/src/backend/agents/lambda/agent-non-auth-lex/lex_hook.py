# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

from dispatch.agent_non_auth_bot import LexV2AgentNonAuthBotDispatcher
from dispatch.lex_helper import *
import logging

logger = get_logger(__name__)
logger.setLevel(logging.INFO)


def dispatch_lexv2(request):
    lexv2_dispatcher = LexV2AgentNonAuthBotDispatcher(request)

    return lexv2_dispatcher.dispatch_intent()


def lambda_handler(event, context):
    print(event)
    if 'sessionState' in event:
        if 'intent' in event['sessionState']:
            if 'name' in event['sessionState']['intent']:
                if event['sessionState']['intent']['name'] == 'FallbackIntent':
                    return dispatch_lexv2(event)