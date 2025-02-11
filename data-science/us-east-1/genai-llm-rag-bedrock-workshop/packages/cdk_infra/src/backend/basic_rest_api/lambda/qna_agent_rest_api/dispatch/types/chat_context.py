# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

from uuid import uuid4

class ChatContext:
    session_id: str
    history: list[dict]
    state: dict

    def __init__(self, session_id: str=None, history: list[dict]=None, state: dict=None):
        if state is None:
            state = {}
        if history is None:
            history = []
        self.session_id = session_id if session_id else str(uuid4())
        self.history = history
        self.state = state

    def to_dict(self):
        return {
            'sessionId': self.session_id,
            'history': self.history,
            'state': self.state
        }

    @staticmethod
    def from_dict(d: dict):
        print()
        return ChatContext(d['sessionId'], d['history'], d['state'])