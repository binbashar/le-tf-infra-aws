from datetime import date

import pytest

from version_support.discover import Pin
from version_support.lifecycle import Finding
from version_support.report import (
    annotations,
    blocking_findings,
    issue_body,
    markdown_table,
    slack_payload,
    slack_summary,
    terminal_table,
)

ACTIVE_EXTENDED = Finding(
    pin=Pin("eks", None, "1.28", "1.28", "apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
            True, "apps-devstg/.../variables.tf:9 (var.cluster_version)"),
    status="EXTENDED_SUPPORT",
    end_standard=date(2024, 11, 26),
    end_extended=date(2025, 11, 26),
    days_left=-647,
    severity="EXTENDED",
)
ACTIVE_SOON = Finding(
    pin=Pin("eks", None, "1.31", "1.31", "shared/us-east-1/k8s-eks/cluster",
            True, "shared/.../variables.tf:9 (var.cluster_version)"),
    status="STANDARD_SUPPORT",
    end_standard=date(2026, 11, 1),
    end_extended=date(2027, 11, 1),
    days_left=58,
    severity="SOON",
)
DISABLED_EXTENDED = Finding(
    pin=Pin("rds", "aurora-mysql", "5.7", "5.7", "apps-devstg/us-east-1/databases-aurora --",
            False, "apps-devstg/.../cluster_demoapps.tf:8"),
    status="EXTENDED_SUPPORT",
    end_standard=date(2024, 10, 31),
    end_extended=date(2027, 10, 31),
    days_left=-673,
    severity="EXTENDED",
)
ACTIVE_UNSUPPORTED = Finding(
    pin=Pin("rds", "aurora-mysql", "5.6", "5.6", "apps-devstg/us-east-1/databases-legacy",
            True, "apps-devstg/.../db.tf:12"),
    status="UNSUPPORTED",
    end_standard=date(2022, 2, 28),
    end_extended=date(2024, 2, 29),
    days_left=-1650,
    severity="UNSUPPORTED",
)


def test_only_active_findings_block():
    result = blocking_findings([ACTIVE_EXTENDED, ACTIVE_SOON, DISABLED_EXTENDED])

    # A disabled layer costs nothing; gating on it would land the check red on
    # day one and keep it red.
    assert result == [ACTIVE_EXTENDED]


def test_annotations_error_on_blocking_and_warn_on_soon():
    lines = annotations([ACTIVE_EXTENDED, ACTIVE_SOON, DISABLED_EXTENDED])

    assert any(line.startswith("::error ") and "1.28" in line for line in lines)
    assert any(line.startswith("::warning ") and "1.31" in line for line in lines)
    assert not any("databases-aurora --" in line for line in lines)


def test_terminal_table_separates_latent_debt():
    text = terminal_table([ACTIVE_EXTENDED, DISABLED_EXTENDED])

    assert "apps-devstg/us-east-1/k8s-eks-demoapps/cluster" in text
    assert "would be in extended support if enabled" in text


def test_markdown_table_is_generated_with_a_date():
    text = markdown_table([ACTIVE_SOON], generated_on=date(2026, 9, 4))

    assert text.startswith("<!-- GENERATED")
    assert "2026-09-04" in text
    assert "| 1.31 |" in text


def test_slack_summary_counts_active_findings_only():
    text = slack_summary([ACTIVE_EXTENDED, ACTIVE_SOON, DISABLED_EXTENDED])

    assert "1 in extended support" in text
    assert "1 within the lead time" in text


def test_a_lone_unknown_finding_does_not_produce_a_contentless_alert():
    # attention_findings() counts UNKNOWN, so an UNKNOWN alone can be the whole
    # reason the scheduled Slack message fires. It must then say so, not read as
    # "nothing is wrong".
    unknown = Finding(
        pin=Pin("eks", None, None, None, "active-unknown", True, "active-unknown/x.tf:5"),
        status="UNKNOWN",
        end_standard=None,
        end_extended=None,
        days_left=None,
        severity="UNKNOWN",
    )

    summary = slack_summary([unknown])

    assert "could not be checked" in summary
    assert "active-unknown" in summary


def test_slack_payload_embeds_the_summary_and_run_url():
    payload = slack_payload(
        [ACTIVE_EXTENDED], repository="binbashar/le-tf-infra-aws", run_url="https://example/run/1"
    )
    section = payload["blocks"][1]

    assert "binbashar/le-tf-infra-aws" in section["text"]["text"]
    assert "1 in extended support" in section["text"]["text"]
    assert section["accessory"]["url"] == "https://example/run/1"


def test_issue_body_carries_the_dedupe_marker():
    body = issue_body([ACTIVE_SOON], generated_on=date(2026, 9, 4))

    assert "<!-- version-support-guardrail -->" in body


def test_unsupported_is_not_described_as_extended_support():
    # UNSUPPORTED is worse than EXTENDED -- past the paid window entirely. Calling
    # it "in extended support" understates the single worst state we can detect.
    summary = slack_summary([ACTIVE_UNSUPPORTED])
    assert "1 unsupported" in summary
    assert "1 in extended support" not in summary

    disabled = Finding(
        pin=Pin("rds", "aurora-mysql", "5.6", "5.6", "databases-legacy --", False,
                "databases-legacy --/db.tf:12"),
        status="UNSUPPORTED",
        end_standard=date(2022, 2, 28),
        end_extended=date(2024, 2, 29),
        days_left=-1650,
        severity="UNSUPPORTED",
    )
    text = terminal_table([disabled])
    assert "unsupported if enabled" in text
    assert "would be in extended support if enabled" not in text


def test_unsupported_still_blocks_and_annotates():
    # The wording fix must not weaken gating.
    assert blocking_findings([ACTIVE_UNSUPPORTED]) == [ACTIVE_UNSUPPORTED]
    assert any(a.startswith("::error ") for a in annotations([ACTIVE_UNSUPPORTED]))


@pytest.mark.parametrize(
    ("source", "expected_file"),
    [
        ("apps-devstg/us-east-1/x/db.tf:33", "apps-devstg/us-east-1/x/db.tf"),
        ("apps-devstg/x/variables.tf:6 (var.cluster_version)", "apps-devstg/x/variables.tf"),
        ("apps-devstg/x/vars.tf:6 (var.v (tfvars))", "apps-devstg/x/vars.tf"),
        ("apps-devstg/x/main.tf", "apps-devstg/x/main.tf"),
        (r"C:\repo\x\main.tf:5", r"C:\repo\x\main.tf"),
    ],
)
def test_annotation_file_path_survives_every_source_shape(source, expected_file):
    finding = Finding(
        pin=Pin("eks", None, "1.28", "1.28", "L", True, source),
        status="EXTENDED_SUPPORT",
        end_standard=date(2024, 11, 26),
        end_extended=date(2025, 11, 26),
        days_left=-647,
        severity="EXTENDED",
    )

    line = annotations([finding])[0]

    assert line.startswith(f"::error file={expected_file}::")
