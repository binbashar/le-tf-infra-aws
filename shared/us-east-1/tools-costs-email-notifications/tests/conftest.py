import json
import pathlib
import sys

import pytest

LAYER = pathlib.Path(__file__).resolve().parent.parent

# src/script.py is zipped as-is into the Lambda package: keep __pycache__ out of src/.
sys.dont_write_bytecode = True


@pytest.fixture
def load_script(monkeypatch):
    """Import src/script.py with the given environment, the way the runtime does.

    The script reads its configuration at import time, so every test imports a
    fresh copy after setting the environment it needs.
    """
    def _load(**env):
        defaults = {
            "SENDER": "reports@example.com",
            "RECIPIENT": "a@example.com,b@example.com",
            "ACCOUNTS": json.dumps({"shared": {"id": "000000000002", "email": ""}}),
            "AUTO_DISCOVER_ACCOUNTS": "false",
            "FORCE_DATE": "2026-11-01",
            "AWS_DEFAULT_REGION": "us-east-1",
        }
        defaults.update(env)
        for key, value in defaults.items():
            if value is None:
                monkeypatch.delenv(key, raising=False)
            else:
                monkeypatch.setenv(key, value)
        monkeypatch.syspath_prepend(str(LAYER / "src"))
        sys.modules.pop("script", None)
        import script
        return script
    yield _load
    sys.modules.pop("script", None)
