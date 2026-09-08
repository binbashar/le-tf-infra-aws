import base64
import json
import logging

import pytest

from lambda_function import BadJson, TooLarge, parse_body


def test_parses_a_plain_json_body():
    event = {"body": json.dumps({"name": "Ada"}), "isBase64Encoded": False}
    assert parse_body(event) == {"name": "Ada"}


def test_parses_a_base64_encoded_body():
    raw = base64.b64encode(json.dumps({"name": "Ada"}).encode()).decode()
    event = {"body": raw, "isBase64Encoded": True}
    assert parse_body(event) == {"name": "Ada"}


def test_missing_body_is_bad_json():
    with pytest.raises(BadJson):
        parse_body({})


def test_non_object_json_is_bad_json():
    # A bare list would sail through a naive json.loads and then blow up in
    # validate() with an AttributeError, i.e. a 500 for what is a client error.
    with pytest.raises(BadJson):
        parse_body({"body": "[1, 2, 3]", "isBase64Encoded": False})


def test_malformed_json_is_bad_json():
    with pytest.raises(BadJson):
        parse_body({"body": "{not json", "isBase64Encoded": False})


def test_body_over_the_cap_is_too_large():
    event = {"body": "x" * (32 * 1024 + 1), "isBase64Encoded": False}
    with pytest.raises(TooLarge):
        parse_body(event)


from lambda_function import ROLES, is_honeypot_filled, validate


def valid_payload(**overrides):
    """A minimal application that passes validate(). Overrides replace fields;
    passing None for a key deletes it, so 'field is missing' is expressible."""
    payload = {
        "name": "Ada Lovelace",
        "email": "ada@example.com",
        "role": "aws-cloud-engineer",
        "country": "Argentina",
        "linkedin": "https://www.linkedin.com/in/ada",
        "experience": "6-9",
        "seniority": "senior",
        "consent": True,
        "locale": "en",
    }
    for key, value in overrides.items():
        if value is None:
            payload.pop(key, None)
        else:
            payload[key] = value
    return payload


def test_a_complete_application_is_valid():
    assert validate(valid_payload()) == []


def test_optional_fields_may_be_absent():
    assert validate(valid_payload(github=None, awsCerts=None, message=None)) == []


def test_optional_fields_are_accepted_when_present():
    payload = valid_payload(
        github="https://github.com/ada",
        awsCerts="https://skillsprofile.skillbuilder.aws/user/ada/certification-badges",
        message="I would like to work on platform engineering.",
    )
    assert validate(payload) == []


@pytest.mark.parametrize(
    "field", ["name", "email", "role", "country", "linkedin", "experience", "seniority", "locale"]
)
def test_every_required_field_is_required(field):
    assert validate(valid_payload(**{field: None})) == [field]


def test_whitespace_only_is_not_a_value():
    assert validate(valid_payload(name="   ")) == ["name"]


@pytest.mark.parametrize("bad", ["ada", "ada@", "@example.com", "a@b@c.com", "ada example.com"])
def test_malformed_emails_are_rejected(bad):
    assert validate(valid_payload(email=bad)) == ["email"]


@pytest.mark.parametrize("slug", list(ROLES))
def test_every_allow_listed_role_is_accepted(slug):
    assert validate(valid_payload(role=slug)) == []


def test_a_role_outside_the_allow_list_is_rejected():
    # The role is the only field that reaches the subject line, so it is an
    # allow-list rather than a free-text passthrough.
    assert validate(valid_payload(role="ceo")) == ["role"]


@pytest.mark.parametrize("field", ["linkedin", "github", "awsCerts"])
def test_urls_must_be_https(field):
    assert validate(valid_payload(**{field: "http://example.com"})) == [field]
    assert validate(valid_payload(**{field: "javascript:alert(1)"})) == [field]


def test_consent_must_be_exactly_true():
    assert validate(valid_payload(consent=False)) == ["consent"]
    assert validate(valid_payload(consent="true")) == ["consent"]
    assert validate(valid_payload(consent=1)) == ["consent"]


def test_experience_and_seniority_are_closed_sets():
    assert validate(valid_payload(experience="20+")) == ["experience"]
    assert validate(valid_payload(seniority="principal")) == ["seniority"]


def test_locale_is_a_closed_set():
    assert validate(valid_payload(locale="fr")) == ["locale"]


def test_over_long_values_are_rejected():
    assert validate(valid_payload(name="a" * 121)) == ["name"]
    assert validate(valid_payload(country="a" * 81)) == ["country"]
    assert validate(valid_payload(message="a" * 4001)) == ["message"]
    assert validate(valid_payload(linkedin="https://x.com/" + "a" * 500)) == ["linkedin"]


def test_every_failing_field_is_reported_not_just_the_first():
    # The client renders a message per field. Bailing on the first failure would
    # make a form with three errors take three round trips to fix.
    assert sorted(validate(valid_payload(email="nope", consent=False))) == ["consent", "email"]


def test_honeypot_empty_or_absent_is_not_filled():
    assert is_honeypot_filled(valid_payload()) is False
    assert is_honeypot_filled(valid_payload(referralSource="")) is False
    assert is_honeypot_filled(valid_payload(referralSource="   ")) is False


def test_honeypot_with_content_is_filled():
    assert is_honeypot_filled(valid_payload(referralSource="Acme Corp")) is True


from lambda_function import render

XSS = '<script>alert("x")</script>'


def test_subject_names_the_role_and_the_applicant():
    subject, _, _ = render(valid_payload())
    assert subject == "[careers] AWS Cloud Engineer — Ada Lovelace"


def test_general_applications_say_so_in_the_subject():
    subject, _, _ = render(valid_payload(role="general"))
    assert subject == "[careers] General application — Ada Lovelace"


def test_html_body_carries_every_submitted_value():
    _, html, _ = render(
        valid_payload(
            github="https://github.com/ada",
            awsCerts="https://skillsprofile.skillbuilder.aws/user/ada/certification-badges",
            message="Platform engineering, please.",
        )
    )
    for expected in [
        "Ada Lovelace",
        "ada@example.com",
        "AWS Cloud Engineer",
        "Argentina",
        "https://www.linkedin.com/in/ada",
        "https://github.com/ada",
        "https://skillsprofile.skillbuilder.aws/user/ada/certification-badges",
        "6-9",
        "senior",
        "Platform engineering, please.",
    ]:
        assert expected in html


def test_text_body_carries_every_submitted_value():
    _, _, text = render(valid_payload(message="Platform engineering, please."))
    for expected in ["Ada Lovelace", "ada@example.com", "AWS Cloud Engineer", "Argentina"]:
        assert expected in text


def test_absent_optional_fields_render_a_dash_not_the_word_none():
    _, html, text = render(valid_payload())
    assert "None" not in html
    assert "None" not in text


@pytest.mark.parametrize(
    "field", ["name", "email", "country", "linkedin", "github", "awsCerts", "message"]
)
def test_script_tags_are_escaped_in_the_html_body(field):
    # Every free-text field goes through this test — the closed-set fields (role,
    # experience, seniority, locale) are excluded because validate() constrains
    # them to a fixed set of safe literals before render() ever sees them, so they
    # cannot carry arbitrary markup in the first place. linkedin/github/awsCerts
    # matter here precisely because the URL check (https:// prefix + length cap)
    # does not forbid a payload like https://x.com/"><script>alert(1)</script>.
    _, html, _ = render(valid_payload(**{field: XSS}))
    assert "<script>" not in html
    assert "&lt;script&gt;" in html


def test_the_escaping_covers_the_subject_too():
    subject, _, _ = render(valid_payload(name=XSS))
    # The subject is a header, not markup — it must carry the raw, UNescaped text.
    # `"alert" in subject` would pass whether or not the subject was escaped
    # (html.escape leaves the word "alert" untouched), so it cannot catch a
    # regression. Pin the literal angle brackets instead: a future "harden
    # render()" pass that starts escaping the subject would redden this test
    # rather than silently shipping &lt;script&gt; into a recruiter's inbox.
    assert "<script>" in subject


def test_quotes_are_escaped_so_an_attribute_cannot_be_broken_out_of():
    # The closing quote after "alert(1)" matters: without it, the raw string never
    # contains `onload="alert(1)"` even when nothing is escaped, so the first
    # assertion could never fail. With it, escaping is the only thing standing
    # between this and a literal onload handler landing in the HTML body.
    _, html, _ = render(valid_payload(name='Ada" onload="alert(1)"'))
    assert 'onload="alert(1)"' not in html
    assert "&quot;" in html


def test_control_characters_cannot_inject_into_the_subject():
    # A literal CR/LF in `name` would ride straight into the Subject header
    # (`[careers] {role} — {name}`) if _text() only trimmed the ends. This is the
    # classic web-form header-injection shape ("Bcc: attacker@evil.com" smuggled
    # in on a second line) — SES's structured SendEmail is not proven to sanitise
    # it on its own, so _text() strips control characters rather than relying on
    # that.
    subject, _, _ = render(valid_payload(name="Ada\r\nBcc: attacker@evil.com"))
    assert "\r" not in subject
    assert "\n" not in subject
    assert "Bcc" in subject  # stripped of control chars, not silently dropped


def test_a_multiline_message_renders_with_br_between_lines_in_the_html_body():
    # Round-1's control-character strip was applied inside the shared _text()
    # helper, so it deleted newlines from every field, `message` included — a
    # regression this test would have caught: it fused "...team." and "Before..."
    # with no space or break at all.
    _, html, _ = render(
        valid_payload(message="I led the platform team.\nBefore that, SRE at Acme.")
    )
    assert "I led the platform team.<br>Before that, SRE at Acme." in html


def test_a_multiline_message_keeps_its_line_break_in_the_text_body():
    _, _, text = render(
        valid_payload(message="I led the platform team.\nBefore that, SRE at Acme.")
    )
    assert "I led the platform team.\nBefore that, SRE at Acme." in text


def test_crlf_in_a_message_does_not_produce_a_doubled_break():
    # \r\n must collapse to one line break, not two — a naive "keep \r and \n
    # both" fix would render a blank line between every paragraph.
    _, html, _ = render(valid_payload(message="Line one.\r\nLine two."))
    assert "Line one.<br>Line two." in html
    assert "<br><br>" not in html


import lambda_function


@pytest.fixture(autouse=True)
def _env(monkeypatch):
    monkeypatch.setenv("SES_FROM_EMAIL", "careers@binbash.co")
    monkeypatch.setenv("CAREERS_RECIPIENT", "people@binbash.com.ar")


@pytest.fixture
def sent(monkeypatch):
    """Capture send() calls instead of reaching SES."""
    calls = []
    monkeypatch.setattr(lambda_function, "send", lambda *args: calls.append(args))
    return calls


def invoke(payload):
    return lambda_function.lambda_handler(
        {"body": json.dumps(payload), "isBase64Encoded": False}, None
    )


def body_of(response):
    return json.loads(response["body"])


def test_a_valid_application_returns_200_and_sends(sent):
    response = invoke(valid_payload())
    assert response["statusCode"] == 200
    assert body_of(response) == {"ok": True}
    assert len(sent) == 1


def test_reply_to_is_the_applicant(sent):
    invoke(valid_payload(email="ada@example.com"))
    _, _, _, reply_to = sent[0]
    assert reply_to == "ada@example.com"


def test_send_calls_ses_with_the_right_kwargs(monkeypatch):
    # Every other test in this file patches send() itself out, which means the
    # body of send() has never actually run under test — a wrong env-var name, a
    # swapped Html/Text part, or a dropped Charset would still ship 60/60 green.
    # Patch _client() instead, one level lower, so send() itself executes.
    calls = []

    class FakeSesClient:
        def send_email(self, **kwargs):
            calls.append(kwargs)

    monkeypatch.setattr(lambda_function, "_client", lambda: FakeSesClient())

    lambda_function.send("Subject line", "<p>html</p>", "text", "ada@example.com")

    assert len(calls) == 1
    kwargs = calls[0]
    assert kwargs["Source"] == "careers@binbash.co"
    assert kwargs["Destination"] == {"ToAddresses": ["people@binbash.com.ar"]}
    assert kwargs["ReplyToAddresses"] == ["ada@example.com"]
    message = kwargs["Message"]
    assert message["Subject"] == {"Data": "Subject line", "Charset": "UTF-8"}
    assert message["Body"]["Html"] == {"Data": "<p>html</p>", "Charset": "UTF-8"}
    assert message["Body"]["Text"] == {"Data": "text", "Charset": "UTF-8"}


def test_validation_failure_returns_400_and_names_the_fields(sent):
    response = invoke(valid_payload(email="nope", consent=False))
    assert response["statusCode"] == 400
    payload = body_of(response)
    assert payload["ok"] is False
    assert payload["error"] == "validation"
    assert sorted(payload["fields"]) == ["consent", "email"]
    assert sent == []


@pytest.mark.parametrize("field", ["role", "experience", "seniority", "locale"])
def test_an_unhashable_closed_set_value_returns_400_not_500(field, sent):
    # payload.get(field) not in ROLES/EXPERIENCE/SENIORITY/LOCALES hashes the
    # value; a list is unhashable, so a naive membership check would raise
    # TypeError inside validate(). lambda_handler's outer try/except Exception
    # would still catch that — it would not escape as an unhandled Lambda error
    # — but it would surface as this module's generic 500 {"ok": false, "error":
    # "server"} instead of the §4 contract of a 400 naming the field.
    # _in_closed_set() guards against that here so any anonymous caller sending
    # a two-character body change (e.g. `"role": []`) still gets the useful 400.
    response = invoke(valid_payload(**{field: []}))
    assert response["statusCode"] == 400
    assert body_of(response)["fields"] == [field]
    assert sent == []


def test_a_filled_honeypot_returns_200_and_sends_nothing(sent):
    # A 400 tells a bot which field caught it. A 200 teaches it nothing.
    response = invoke(valid_payload(referralSource="Acme Corp"))
    assert response["statusCode"] == 200
    assert body_of(response) == {"ok": True}
    assert sent == []


def test_a_filled_honeypot_wins_even_when_the_rest_is_invalid(sent):
    response = invoke(valid_payload(referralSource="Acme", email="nope"))
    assert response["statusCode"] == 200
    assert sent == []


def test_an_oversized_body_returns_413(sent):
    response = lambda_function.lambda_handler(
        {"body": "x" * (32 * 1024 + 1), "isBase64Encoded": False}, None
    )
    assert response["statusCode"] == 413
    assert body_of(response)["error"] == "too_large"
    assert sent == []


def test_malformed_json_returns_400(sent):
    response = lambda_function.lambda_handler({"body": "{nope", "isBase64Encoded": False}, None)
    assert response["statusCode"] == 400
    assert sent == []


def test_an_ses_failure_returns_500_with_no_internals_in_the_body(monkeypatch):
    def explode(*_args):
        raise RuntimeError("AccessDenied: ses:SendEmail on arn:aws:ses:...")

    monkeypatch.setattr(lambda_function, "send", explode)
    response = invoke(valid_payload())
    assert response["statusCode"] == 500
    assert body_of(response) == {"ok": False, "error": "server"}
    assert "AccessDenied" not in response["body"]


def test_every_response_carries_json_content_type(sent):
    assert invoke(valid_payload())["headers"]["Content-Type"] == "application/json"


def test_an_unhandled_exception_still_returns_the_500_contract(sent, monkeypatch):
    # A backstop, not a substitute for fixing specific bugs: if some future code
    # path raises anywhere between parsing and sending, the handler must still
    # answer with the §4 shape rather than letting API Gateway's own unhandled-
    # error 500 (a bare {"message": "Internal Server Error"}) leak through.
    def explode(_payload):
        raise RuntimeError("boom")

    monkeypatch.setattr(lambda_function, "validate", explode)
    response = invoke(valid_payload())
    assert response["statusCode"] == 500
    assert body_of(response) == {"ok": False, "error": "server"}
    assert sent == []


@pytest.mark.parametrize(
    "value,expected",
    [
        ("DEBUG", logging.DEBUG),
        ("warning", logging.WARNING),
        ("nonsense", logging.INFO),
        (None, logging.INFO),
    ],
)
def test_log_level_falls_back_to_info_for_garbage(monkeypatch, value, expected):
    # logging.getLogger() with no name is the ROOT logger — setting its level from
    # an unvalidated LOG_LEVEL would also gate botocore's own logging, and an
    # unrecognised value must not raise at import time (a cold-start failure).
    if value is None:
        monkeypatch.delenv("LOG_LEVEL", raising=False)
    else:
        monkeypatch.setenv("LOG_LEVEL", value)
    assert lambda_function._log_level() == expected


def test_logger_is_not_the_root_logger():
    assert lambda_function.LOGGER.name != "root"
