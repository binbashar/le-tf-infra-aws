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
