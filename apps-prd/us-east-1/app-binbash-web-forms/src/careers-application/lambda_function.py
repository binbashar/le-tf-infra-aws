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


# Slug → display name. The slugs are the six /people/careers/<slug> routes plus a
# general application; they are also what reaches the email subject, which is why
# this is an allow-list and not a free-text field.
ROLES = {
    "presales-solutions-architect": "Presales Solutions Architect",
    "tech-delivery-manager": "Tech Delivery Manager",
    "aws-cloud-engineer": "AWS Cloud Engineer",
    "ai-ml-engineer": "AI/ML Engineer",
    "data-engineer": "Data Engineer",
    "partner-account-manager": "Partner Account Manager",
    "general": "General application",
}

EXPERIENCE = frozenset({"0-2", "3-5", "6-9", "10+"})
SENIORITY = frozenset({"junior", "semi-senior", "senior", "lead"})
LOCALES = frozenset({"en", "es", "pt"})

MAX_LENGTHS = {
    "name": 120,
    "email": 254,
    "country": 80,
    "linkedin": 500,
    "github": 500,
    "awsCerts": 500,
    "message": 4000,
}

_REQUIRED_TEXT = ("name", "email", "country", "linkedin")
_URL_FIELDS = ("linkedin", "github", "awsCerts")


def _text(payload, field):
    """The field as a trimmed string, or '' for anything that is not a string."""
    value = payload.get(field)
    return value.strip() if isinstance(value, str) else ""


def is_honeypot_filled(payload):
    """True when the hidden `company` field carries content.

    A human never sees this field. A bot that fills every input does. The caller
    answers 200 anyway — see lambda_handler.
    """
    return bool(_text(payload, "company"))


def _email_looks_valid(value):
    """One @, something on each side of it, no whitespace.

    Deliberately not a full RFC 5322 parse: the only thing riding on this is
    whether Reply-To will work, and a stricter regex rejects valid addresses far
    more often than it catches invalid ones.
    """
    if value.count("@") != 1:
        return False
    local, _, domain = value.partition("@")
    if not local or not domain or "." not in domain:
        return False
    return not any(c.isspace() for c in value)


def validate(payload):
    """Return the names of every failing field. Empty list means valid.

    Every field is checked; the function does not bail on the first failure,
    because the client renders one message per field.
    """
    failed = []

    for field in _REQUIRED_TEXT:
        value = _text(payload, field)
        if not value or len(value) > MAX_LENGTHS[field]:
            failed.append(field)

    if "email" not in failed and not _email_looks_valid(_text(payload, "email")):
        failed.append("email")

    for field in _URL_FIELDS:
        value = _text(payload, field)
        if not value:
            continue  # required-ness for linkedin is already covered above
        if not value.startswith("https://") or len(value) > MAX_LENGTHS[field]:
            if field not in failed:
                failed.append(field)

    if payload.get("role") not in ROLES:
        failed.append("role")
    if payload.get("experience") not in EXPERIENCE:
        failed.append("experience")
    if payload.get("seniority") not in SENIORITY:
        failed.append("seniority")
    if payload.get("locale") not in LOCALES:
        failed.append("locale")

    # `is True`, not truthy: the string "true" and the integer 1 are both a client
    # bug, and a consent checkbox that accepts a coerced value is not consent.
    if payload.get("consent") is not True:
        failed.append("consent")

    message = _text(payload, "message")
    if len(message) > MAX_LENGTHS["message"]:
        failed.append("message")

    return failed
