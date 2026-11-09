import pathlib
import sys

import pytest

LAYER = pathlib.Path(__file__).resolve().parent.parent

# src/ is zipped as-is into the Lambda package: keep __pycache__ out of it.
sys.dont_write_bytecode = True
sys.path.insert(0, str(LAYER / "src"))
sys.path.insert(0, str(LAYER / "tests"))

import report  # noqa: E402


@pytest.fixture(autouse=True)
def no_aws(monkeypatch):
    """Fail any test that reaches AWS: sample data stands in for it."""
    def _refuse(*args, **kwargs):
        raise AssertionError(f"unexpected AWS client: {args}")
    monkeypatch.setattr(report.boto3, "client", _refuse)
