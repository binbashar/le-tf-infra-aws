"""Shared fixtures for the version-support tests.

One job: keep boto3's process-global state from leaking between tests.
"""

import boto3
import pytest


@pytest.fixture(autouse=True)
def no_cached_boto3_session():
    """Drop boto3's module-level default session around every test.

    ``boto3.client(...)`` lazily creates and then CACHES a session in
    ``boto3.DEFAULT_SESSION``, and a botocore session memoises both its parsed
    config files and its resolved credentials. The first test to build a real
    client therefore freezes whatever AWS configuration the environment had at
    that moment, and every later test in the process inherits it -- including
    tests that deliberately scrub ``AWS_*`` and point ``AWS_CONFIG_FILE`` at a
    nonexistent path to prove the scanner degrades when AWS is unreachable.

    Observed, not theoretical: ``test_lifecycle.py`` builds stubbed clients, so on
    a developer machine whose ``AWS_CONFIG_FILE`` has a working ``[default]``
    profile, ``test_no_aws_configuration_degrades_instead_of_crashing`` reached
    live AWS through that cached session, got real findings back and returned 1.
    It failed in the full suite while passing in isolation, and was green in CI
    only because the runner has no default profile at that step -- i.e. the check
    that matters most was unverified exactly where someone would run it by hand.
    """
    boto3.DEFAULT_SESSION = None
    yield
    boto3.DEFAULT_SESSION = None
