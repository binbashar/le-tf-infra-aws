import base64
import json

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
    assert is_honeypot_filled(valid_payload(company="")) is False
    assert is_honeypot_filled(valid_payload(company="   ")) is False


def test_honeypot_with_content_is_filled():
    assert is_honeypot_filled(valid_payload(company="Acme Corp")) is True


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


@pytest.mark.parametrize("field", ["name", "country", "message"])
def test_script_tags_are_escaped_in_the_html_body(field):
    _, html, _ = render(valid_payload(**{field: XSS}))
    assert "<script>" not in html
    assert "&lt;script&gt;" in html


def test_the_escaping_covers_the_subject_too():
    subject, _, _ = render(valid_payload(name=XSS))
    # The subject is a header, not markup — it must carry the raw text, and it
    # must not have been silently dropped.
    assert "alert" in subject


def test_quotes_are_escaped_so_an_attribute_cannot_be_broken_out_of():
    _, html, _ = render(valid_payload(name='Ada" onload="alert(1)'))
    assert 'onload="alert(1)"' not in html
    assert "&quot;" in html
