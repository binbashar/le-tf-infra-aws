"""Careers application form handler.

Receives the JSON the binbash.co careers form posts, validates it, and emails it
to the hiring inbox through SES. Contract:
bb-sales-tools/docs/superpowers/specs/2026-09-08-careers-application-form-design.md §4

Four functions, deliberately: parse_body, validate and render are pure — no boto3,
no environment — so the whole validation and escaping surface is testable with no
AWS credentials. send() is the only part that touches AWS.
"""

import base64
import json

MAX_BODY_BYTES = 32 * 1024


class TooLarge(Exception):
    """Raw request body exceeded MAX_BODY_BYTES."""


class BadJson(Exception):
    """Body was absent, not valid JSON, or not a JSON object."""


def parse_body(event):
    """Return the request body as a dict.

    API Gateway hands the body through base64 when it decides the content is
    binary, which it can do on a payload we consider text, so both shapes are
    handled rather than assumed.
    """
    raw = event.get("body")
    if raw is None:
        raise BadJson("no body")

    if len(raw) > MAX_BODY_BYTES:
        raise TooLarge(f"body over {MAX_BODY_BYTES} bytes")

    if event.get("isBase64Encoded"):
        try:
            raw = base64.b64decode(raw).decode("utf-8")
        except (ValueError, UnicodeDecodeError) as exc:
            raise BadJson("undecodable base64 body") from exc

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise BadJson("malformed JSON") from exc

    # A list or a bare string parses fine and then fails inside validate() with an
    # AttributeError — a 500 for what is squarely a client error. Reject here.
    if not isinstance(payload, dict):
        raise BadJson("body is not a JSON object")

    return payload
