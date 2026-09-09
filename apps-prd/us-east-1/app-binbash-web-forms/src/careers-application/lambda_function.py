"""Careers application form handler.

Receives the JSON the binbash.co careers form posts, validates it, and emails it
to the hiring inbox through SES. Contract:
bb-sales-tools/docs/superpowers/specs/2026-09-08-careers-application-form-design.md §4

Four functions, deliberately: parse_body, validate and render are pure — no boto3,
no environment — so the whole validation and escaping surface is testable with no
AWS credentials. send() is the only part that touches AWS.
"""

import base64
import html as html_module
import json
import logging
import os

import boto3

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

# C0 controls (0x00-0x1F) plus DEL (0x7F), removed rather than merely trimmed off
# the ends: a literal CR/LF in `name` would otherwise ride straight into the
# Subject header (`[careers] {role} — {name}`), and SES's structured SendEmail
# call is not proven to sanitise that on its own.
#
# `message` is the one exception (see keep_newlines below): it's a textarea,
# where a line break is meaningful content rather than a header-injection
# vector, so a second table removes every control character EXCEPT LF (0x0A).
# CR (0x0D) is still removed either way, so a Windows-style \r\n collapses to a
# single \n instead of becoming a doubled break.
_STRIP_ALL_CONTROL = str.maketrans("", "", "".join(chr(c) for c in list(range(0x20)) + [0x7F]))
_STRIP_CONTROL_KEEP_LF = str.maketrans(
    "", "", "".join(chr(c) for c in list(range(0x20)) if c != 0x0A) + chr(0x7F)
)


def _text(payload, field, keep_newlines=False):
    """The field as a trimmed string with control characters removed, or '' for
    anything that is not a string.

    keep_newlines=True preserves internal `\\n` (but not `\\r`) and is passed only
    for `message` — every other field, `name` in particular, keeps the strict
    default so nothing can smuggle a line break into the Subject header.
    """
    value = payload.get(field)
    if not isinstance(value, str):
        return ""
    table = _STRIP_CONTROL_KEEP_LF if keep_newlines else _STRIP_ALL_CONTROL
    return value.translate(table).strip()


def _in_closed_set(value, allowed):
    """Membership check that treats an unhashable value (a list or dict sent
    where a string was expected) as simply "not a member" instead of raising.

    `value in allowed` — allowed being a dict or frozenset — hashes value first.
    A client posting `{"role": []}` would otherwise raise TypeError here. That
    would still be caught by lambda_handler's outer try/except Exception (see
    its docstring), so it would not escape as an unhandled Lambda error — but it
    would surface as this module's generic 500 {"ok": false, "error": "server"}
    instead of the more useful §4 contract of a 400 naming the offending field.
    """
    return isinstance(value, str) and value in allowed


# Named `referralSource`, not `company`: on the actual form this hidden field
# sits in a section that also collects a person's name and address, and Chrome
# (plus 1Password and LastPass) autofills anything that looks like an
# organization field — name="company", id="careers-company", label "Company" —
# regardless of autocomplete="off". This function cannot tell a real applicant
# whose browser autofilled the honeypot from a bot that fills every field, so a
# name that triggers autofill silently loses real applications (a 200 with
# nothing sent, and no signal to anyone that it happened). `referralSource`
# carries no such autofill signal — do not rename it back to something more
# natural-sounding.
def is_honeypot_filled(payload):
    """True when the hidden `referralSource` field carries content.

    A human never sees this field. A bot that fills every input does. The caller
    answers 200 anyway — see lambda_handler.
    """
    return bool(_text(payload, "referralSource"))


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

    if not _in_closed_set(payload.get("role"), ROLES):
        failed.append("role")
    if not _in_closed_set(payload.get("experience"), EXPERIENCE):
        failed.append("experience")
    if not _in_closed_set(payload.get("seniority"), SENIORITY):
        failed.append("seniority")
    if not _in_closed_set(payload.get("locale"), LOCALES):
        failed.append("locale")

    # `is True`, not truthy: the string "true" and the integer 1 are both a client
    # bug, and a consent checkbox that accepts a coerced value is not consent.
    if payload.get("consent") is not True:
        failed.append("consent")

    message = _text(payload, "message", keep_newlines=True)
    if len(message) > MAX_LENGTHS["message"]:
        failed.append("message")

    return failed


# Order matters: this is the order a recruiter reads them in.
_FIELD_LABELS = (
    ("name", "Name"),
    ("email", "Email"),
    ("country", "Country"),
    ("experience", "Years of experience"),
    ("seniority", "Seniority"),
    ("linkedin", "LinkedIn"),
    ("github", "GitHub / portfolio"),
    ("awsCerts", "AWS certifications"),
)


def render(payload):
    """Build (subject, html_body, text_body) from a validated payload.

    THE ONLY PLACE ESCAPING HAPPENS. Every value below goes through
    html.escape(quote=True) before it reaches the HTML body — quote=True because
    a bare `"` in a name is enough to break out of an attribute. This app's own
    monorepo shipped exactly this bug once (AI Use Case Lab SES notification,
    fixed in PR #173), which is why every free-text field has its own escaping
    test (name, email, country, linkedin, github, awsCerts, message). The
    closed-set fields — role, experience, seniority, locale — are excluded from
    that set of tests because validate() constrains them to a fixed handful of
    safe literals before render() ever runs; they still pass through
    html.escape() here, just without a dedicated adversarial test.

    The subject is a header, not markup, so it carries the raw value: escaping it
    would put `&lt;` in a recruiter's inbox.
    """
    role_label = ROLES[payload["role"]]
    name = _text(payload, "name")
    subject = f"[careers] {role_label} — {name}"

    values = {key: _text(payload, key) for key, _ in _FIELD_LABELS}
    values["experience"] = payload["experience"]
    values["seniority"] = payload["seniority"]
    message = _text(payload, "message", keep_newlines=True)

    rows = []
    text_lines = [f"{role_label} — {name}", ""]
    for key, label in _FIELD_LABELS:
        raw = values.get(key) or "—"
        rows.append(
            "<tr>"
            f'<td style="padding:6px 16px 6px 0;color:#6b6b60;vertical-align:top;">{html_module.escape(label, quote=True)}</td>'
            f'<td style="padding:6px 0;">{html_module.escape(raw, quote=True)}</td>'
            "</tr>"
        )
        text_lines.append(f"{label}: {raw}")

    # message is the one field _text() lets keep internal newlines (keep_newlines
    # above) — escape first, then turn each surviving \n into a <br> so multi-
    # paragraph messages don't fuse into one line in the HTML body. The plain
    # text body needs no such conversion: a literal \n already reads as a line
    # break there.
    escaped_message = html_module.escape(message or "—", quote=True).replace("\n", "<br>")
    text_lines += ["", "Message:", message or "—"]

    html_body = (
        '<html><body style="font-family:system-ui,-apple-system,sans-serif;color:#181917;">'
        f"<h2 style=\"margin:0 0 4px;\">{html_module.escape(role_label, quote=True)}</h2>"
        f'<p style="margin:0 0 16px;color:#6b6b60;">Application received from binbash.co '
        f'({html_module.escape(payload["locale"], quote=True)})</p>'
        f'<table style="border-collapse:collapse;font-size:14px;">{"".join(rows)}</table>'
        f'<h3 style="margin:24px 0 4px;">Message</h3>'
        f'<p style="margin:0;font-size:14px;">{escaped_message}</p>'
        "</body></html>"
    )

    return subject, html_body, "\n".join(text_lines)


_LOG_LEVELS = {
    "DEBUG": logging.DEBUG,
    "INFO": logging.INFO,
    "WARNING": logging.WARNING,
    "ERROR": logging.ERROR,
    "CRITICAL": logging.CRITICAL,
}


def _log_level():
    """LOG_LEVEL from the environment, validated against a fixed table.

    A malformed value (or logging.getLogger().setLevel's own behaviour of
    raising ValueError on one) must not crash a cold start; it falls back to
    INFO instead.
    """
    return _LOG_LEVELS.get(os.environ.get("LOG_LEVEL", "INFO").upper(), logging.INFO)


# getLogger(__name__), not getLogger() — the latter is the ROOT logger, so
# LOG_LEVEL=DEBUG would also pull botocore's own request logging into CloudWatch.
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(_log_level())

_ses = None


def _client():
    """Lazily built so importing this module needs no credentials — which is what
    lets the test suite run anywhere."""
    global _ses
    if _ses is None:
        _ses = boto3.client("ses")
    return _ses


def send(subject, html_body, text_body, reply_to):
    """One SES SendEmail. Raises whatever boto3 raises; the handler maps it."""
    _client().send_email(
        Source=os.environ["SES_FROM_EMAIL"],
        Destination={"ToAddresses": [os.environ["CAREERS_RECIPIENT"]]},
        ReplyToAddresses=[reply_to],
        Message={
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {
                "Html": {"Data": html_body, "Charset": "UTF-8"},
                "Text": {"Data": text_body, "Charset": "UTF-8"},
            },
        },
    )


def _response(status, payload):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }


def lambda_handler(event, _context):
    """Validate, then send. See the spec's §4 for the response table.

    CORS headers are NOT set here — the HTTP API's own `cors_configuration` adds
    them to every response, including the ones this function returns, and IGNORES
    whatever Access-Control-* headers the integration (this Lambda) sends back —
    its copy is dropped, not merged. Setting them here too would be inert, not a
    duplicated header.

    The whole body runs under one outer try/except Exception. validate() already
    guards every closed-set membership check against unhashable input (see
    _in_closed_set), so this is a backstop rather than a fix for a known bug: it
    exists so that a *future* bug here trades API Gateway's own unhandled-error
    500 (a bare {"message": "Internal Server Error"}) for this module's §4
    contract of {"ok": false, "error": "server"} instead.
    """
    try:
        try:
            payload = parse_body(event)
        except TooLarge:
            return _response(413, {"ok": False, "error": "too_large"})
        except BadJson:
            return _response(400, {"ok": False, "error": "validation", "fields": []})

        # Before validation on purpose: a bot that fills every field would otherwise
        # get a 400 listing what it got wrong.
        if is_honeypot_filled(payload):
            LOGGER.info("honeypot filled; dropping submission")
            return _response(200, {"ok": True})

        failed = validate(payload)
        if failed:
            LOGGER.info("validation failed for fields: %s", ",".join(failed))
            return _response(400, {"ok": False, "error": "validation", "fields": failed})

        subject, html_body, text_body = render(payload)

        try:
            send(subject, html_body, text_body, _text(payload, "email"))
        except Exception:
            # exception() logs the traceback to CloudWatch; the body says nothing, so
            # an IAM or SES error never reaches a browser.
            LOGGER.exception("SES send failed")
            return _response(500, {"ok": False, "error": "server"})

        LOGGER.info("application sent for role=%s", payload["role"])
        return _response(200, {"ok": True})
    except Exception:
        LOGGER.exception("unhandled error in lambda_handler")
        return _response(500, {"ok": False, "error": "server"})
