import json
import pathlib
import sys

import pytest

LAYER = pathlib.Path(__file__).resolve().parent.parent
FIXTURES = LAYER / "tests" / "fixtures"

# src/ is zipped as-is into the Lambda package: keep __pycache__ out of it.
sys.dont_write_bytecode = True

# The Lambda package is src/ itself, so import the handler the way the
# runtime does: as a top-level module.
sys.path.insert(0, str(LAYER / "src"))

import handler  # noqa: E402


@pytest.fixture
def load_fixture():
    def _load(name):
        return json.loads((FIXTURES / name).read_text())
    return _load


@pytest.fixture(autouse=True)
def no_aws(monkeypatch):
    """Fail any test that reaches AWS: fixtures stand in for Cost Explorer."""
    def _refuse(*args, **kwargs):
        raise AssertionError(f"unexpected AWS client: {args}")
    monkeypatch.setattr(handler.boto3, "client", _refuse)
    for var in ("CREDITS_EXPIRE_DATE", "AWS_ACCOUNT_NAME"):
        monkeypatch.delenv(var, raising=False)
