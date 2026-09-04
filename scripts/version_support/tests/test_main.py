import os
from datetime import date
from unittest import mock

import pytest

from version_support.__main__ import main
from version_support.discover import Pin
from version_support.lifecycle import Finding, LookupUnavailable

FIXTURE_TREE = os.path.join(os.path.dirname(__file__), "fixtures", "tree")

BLOCKING_FINDING = Finding(
    pin=Pin("eks", None, "1.28", "1.28", "apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
            True, "main.tf:5"),
    status="EXTENDED_SUPPORT",
    end_standard=date(2024, 11, 26),
    end_extended=date(2025, 11, 26),
    days_left=-647,
    severity="EXTENDED",
)
DISABLED_FINDING = Finding(
    pin=Pin("rds", "aurora-mysql", "5.7", "5.7", "apps-devstg/us-east-1/databases-aurora --",
            False, "cluster.tf:8"),
    status="EXTENDED_SUPPORT",
    end_standard=date(2024, 10, 31),
    end_extended=date(2027, 10, 31),
    days_left=-673,
    severity="EXTENDED",
)


def test_pr_mode_fails_on_an_active_blocking_finding():
    with mock.patch("version_support.__main__.collect", return_value=([BLOCKING_FINDING], [])):
        assert main(["--mode", "pr", "--root", FIXTURE_TREE]) == 1


def test_pr_mode_passes_when_only_disabled_layers_are_blocking():
    with mock.patch("version_support.__main__.collect", return_value=([DISABLED_FINDING], [])):
        assert main(["--mode", "pr", "--root", FIXTURE_TREE]) == 0


def test_cron_mode_never_fails():
    with mock.patch("version_support.__main__.collect", return_value=([BLOCKING_FINDING], [])):
        assert main(["--mode", "cron", "--root", FIXTURE_TREE]) == 0


def test_pr_mode_does_not_block_when_aws_is_unavailable():
    with mock.patch("version_support.__main__.collect", side_effect=LookupUnavailable("boom")):
        # Never block a merge on an AWS outage - but say so loudly.
        assert main(["--mode", "pr", "--root", FIXTURE_TREE]) == 0


def test_table_mode_writes_the_status_file(tmp_path):
    target = tmp_path / "status.md"
    with mock.patch("version_support.__main__.collect", return_value=([BLOCKING_FINDING], [])):
        assert main(["--mode", "table", "--root", FIXTURE_TREE, "--out", str(target)]) == 0

    assert "GENERATED" in target.read_text()


def test_a_client_construction_failure_degrades_instead_of_crashing(monkeypatch, tmp_path):
    # boto3 can fail before any network call (NoRegionError when no region
    # resolves). Every other test mocks collect() wholesale, so none of them
    # exercise real client construction -- which is exactly where this escaped.
    from botocore.exceptions import NoRegionError

    def refuse(*args, **kwargs):
        raise NoRegionError()

    monkeypatch.setattr("version_support.__main__.boto3.client", refuse)

    # Neither mode may crash or block: the check did not run, and says so.
    assert main(["--mode", "pr", "--root", str(tmp_path)]) == 0
    assert main(["--mode", "cron", "--root", str(tmp_path)]) == 0
