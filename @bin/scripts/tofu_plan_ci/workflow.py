"""Run the imperative parts of the OpenTofu GitHub Actions workflow."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
from pathlib import Path
from typing import Mapping, Sequence

from . import aggregate as aggregate_report
from . import bedrock_analysis, discover, plan_report

PROFILE = re.compile(
    r'^\s*profile\s*=\s*"(?P<profile>[A-Za-z0-9_-]+)"\s*(?:#.*)?$'
)
DENIED_ACTION = re.compile(
    r"not authorized to perform:\s*([a-z0-9-]+:[A-Za-z][A-Za-z0-9]*)",
    re.IGNORECASE,
)


def _required_env(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        raise ValueError(f"required environment variable is empty: {name}")
    return value


def _append(path: str | None, content: str) -> None:
    if not path:
        return
    with Path(path).open("a", encoding="utf-8") as stream:
        stream.write(content)


def _output(name: str, value: str) -> None:
    _append(os.environ.get("GITHUB_OUTPUT"), f"{name}={value}\n")


def _summary(path: Path) -> None:
    if path.is_file():
        _append(os.environ.get("GITHUB_STEP_SUMMARY"), path.read_text(encoding="utf-8"))


def layer_slug(layer: str) -> str:
    slug = re.sub(r"[^A-Za-z0-9_.-]", "", layer.replace("/", "-").replace(" ", "-"))
    if not slug:
        raise ValueError("layer does not produce a usable artifact slug")
    return slug


def read_backend_profile(path: Path) -> str:
    for line in path.read_text(encoding="utf-8").splitlines():
        if match := PROFILE.match(line):
            return match.group("profile")
    raise ValueError(f"could not resolve a safe AWS profile from {path}")


def _layer_paths(layer: str) -> tuple[str, Path]:
    slug = layer_slug(layer)
    report_dir = Path(_required_env("RUNNER_TEMP")) / "tofu-plan-poc-report" / slug
    report_dir.mkdir(parents=True, exist_ok=True)
    _output("slug", slug)
    _output("report_dir", str(report_dir))
    return slug, report_dir


def run_logged(
    command: Sequence[str],
    *,
    stdout_path: Path,
    stderr_path: Path | None = None,
    env: Mapping[str, str] | None = None,
) -> int:
    """Run a command while keeping its potentially sensitive output off the console."""

    stdout_path.parent.mkdir(parents=True, exist_ok=True)
    stderr_stream = None
    try:
        with stdout_path.open("wb") as stdout:
            if stderr_path:
                stderr_path.parent.mkdir(parents=True, exist_ok=True)
                stderr_stream = stderr_path.open("wb")
                stderr = stderr_stream
            else:
                stderr = subprocess.STDOUT
            try:
                return subprocess.run(
                    list(command),
                    check=False,
                    env=dict(env) if env else None,
                    stdout=stdout,
                    stderr=stderr,
                ).returncode
            except OSError as error:
                stdout.write(f"command could not start: {error}\n".encode())
                return 127
    finally:
        if stderr_stream:
            stderr_stream.close()


def denied_action_from_logs(paths: Sequence[Path]) -> str | None:
    """Extract only a denied IAM action; never retain arbitrary error text."""

    for path in paths:
        if not path.is_file():
            continue
        if match := DENIED_ACTION.search(path.read_text(encoding="utf-8", errors="replace")):
            return match.group(1)
    return None


def diagnostic_summary_from_logs(paths: Sequence[Path]) -> str | None:
    """Keep only OpenTofu's structured error summary, never its detail text."""

    for path in paths:
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            try:
                summary = json.loads(line).get("diagnostic", {}).get("summary")
            except json.JSONDecodeError:
                continue
            if isinstance(summary, str) and summary:
                safe = plan_report.redact_text(summary)
                safe = re.sub(r"[^A-Za-z0-9 .,:;_/-]", "?", safe)[:160].strip()
                if safe and re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 .,:;_/-]{0,159}", safe):
                    return safe
    return None


def _metadata_args() -> list[str]:
    return [
        "--repository",
        os.environ.get("GITHUB_REPOSITORY", "unknown"),
        "--head-sha",
        os.environ.get("HEAD_SHA", "unknown"),
        "--merge-sha",
        os.environ.get("GITHUB_SHA", "unknown"),
        "--run-id",
        os.environ.get("GITHUB_RUN_ID", "unknown"),
        "--run-attempt",
        os.environ.get("GITHUB_RUN_ATTEMPT", "unknown"),
    ]


def run_discovery() -> int:
    root = Path(_required_env("GITHUB_WORKSPACE"))
    out_dir = Path(_required_env("RUNNER_TEMP")) / "tofu-plan-poc-discovery"
    output = out_dir / "discovery.json"
    markdown = out_dir / "discovery.md"
    args = [
        "--root",
        str(root),
        "--allow-layer",
        _required_env("POC_LAYER"),
        "--max-layers",
        os.environ.get("MAX_LAYERS", "1"),
        "--out",
        str(output),
        "--markdown-out",
        str(markdown),
    ]
    if os.environ.get("GITHUB_EVENT_NAME") == "workflow_dispatch":
        args.extend(["--layer", os.environ.get("MANUAL_LAYER") or _required_env("POC_LAYER")])
    else:
        args.extend(
            [
                "--base",
                _required_env("BASE_SHA"),
                "--head",
                _required_env("HEAD_SHA"),
            ]
        )

    discover.main(args)
    result = json.loads(output.read_text(encoding="utf-8"))
    _output("layers", json.dumps(result["layers"], separators=(",", ":")))
    _output("has_layers", str(bool(result["layers"])).lower())
    _output("blocked", str(bool(result.get("blocked_reason"))).lower())
    _output("live_eligible", str(bool(result.get("live_eligible", True))).lower())
    _summary(markdown)
    return 0


def run_static(layer: str) -> int:
    _, report_dir = _layer_paths(layer)
    runner_temp = Path(_required_env("RUNNER_TEMP"))
    init_exit = run_logged(
        [
            "tofu",
            f"-chdir={layer}",
            "init",
            "-backend=false",
            "-input=false",
            "-lockfile=readonly",
            "-no-color",
        ],
        stdout_path=runner_temp / "tofu-init.log",
    )
    validate_exit = 99
    if init_exit == 0:
        validate_exit = run_logged(
            ["tofu", f"-chdir={layer}", "validate", "-no-color"],
            stdout_path=runner_temp / "tofu-validate.log",
        )

    plan_report.main(
        [
            "static",
            "--layer",
            layer,
            "--init-exit",
            str(init_exit),
            "--validate-exit",
            str(validate_exit),
            "--out-dir",
            str(report_dir),
            *_metadata_args(),
        ]
    )
    _summary(report_dir / "summary.md")
    if init_exit == 0 and validate_exit == 0:
        return 0
    print(f"::error::Credential-free init or validate failed for {layer}")
    return 1


def _write_aws_profile(directory: Path, *, profile: str, region: str) -> dict[str, str]:
    credentials = {
        "aws_access_key_id": _required_env("AWS_ACCESS_KEY_ID"),
        "aws_secret_access_key": _required_env("AWS_SECRET_ACCESS_KEY"),
        "aws_session_token": _required_env("AWS_SESSION_TOKEN"),
    }
    if any("\n" in value or "\r" in value for value in credentials.values()):
        raise ValueError("AWS credential environment variables contain a newline")

    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    directory.chmod(0o700)
    config = directory / "config"
    credentials_file = directory / "credentials"
    config.write_text(f"[profile {profile}]\nregion = {region}\n", encoding="utf-8")
    credentials_file.write_text(
        f"[{profile}]\n"
        + "".join(f"{name} = {value}\n" for name, value in credentials.items()),
        encoding="utf-8",
    )
    config.chmod(0o600)
    credentials_file.chmod(0o600)
    process_env = os.environ.copy()
    process_env.update(
        {
            "AWS_CONFIG_FILE": str(config),
            "AWS_SHARED_CREDENTIALS_FILE": str(credentials_file),
            "AWS_PROFILE": profile,
        }
    )
    return process_env


def run_live(layer: str) -> int:
    slug, report_dir = _layer_paths(layer)
    workspace = Path(
        os.environ.get("CANDIDATE_ROOT") or _required_env("GITHUB_WORKSPACE")
    ).resolve()
    runner_temp = Path(_required_env("RUNNER_TEMP"))
    layer_dir = workspace / layer
    common_tfvars = workspace / "config" / "common.tfvars"
    plan_file = runner_temp / f"tofu-plan-{slug}"
    plan_json = runner_temp / f"tofu-plan-{slug}.json"
    init_exit = validate_exit = plan_exit = 99
    failure_stage = None
    denied_action = None
    failure_diagnostic = None

    try:
        allowed_layer = _required_env("POC_LAYER")
        if layer != allowed_layer:
            raise ValueError(f"live plan layer is not the configured POC layer: {layer}")
        common = _required_env("COMMON_TFVARS")
        common_tfvars.write_text(common.rstrip("\n") + "\n", encoding="utf-8")
        common_tfvars.chmod(0o600)

        account = layer.split("/", 1)[0]
        backend_config = workspace / account / "config" / "backend.tfvars"
        account_config = workspace / account / "config" / "account.tfvars"
        profile = read_backend_profile(backend_config)
        process_env = _write_aws_profile(
            runner_temp / "aws",
            profile=profile,
            region=os.environ.get("AWS_REGION", "us-east-1"),
        )

        init_exit = run_logged(
            [
                "tofu",
                f"-chdir={layer_dir}",
                "init",
                "-reconfigure",
                "-input=false",
                "-lockfile=readonly",
                "-no-color",
                f"-backend-config={backend_config}",
            ],
            stdout_path=runner_temp / "tofu-live-init.log",
            env=process_env,
        )
        if init_exit == 0:
            validate_exit = run_logged(
                ["tofu", f"-chdir={layer_dir}", "validate", "-no-color"],
                stdout_path=runner_temp / "tofu-live-validate.log",
                env=process_env,
            )
        if validate_exit == 0:
            plan_exit = run_logged(
                [
                    "tofu",
                    f"-chdir={layer_dir}",
                    "plan",
                    "-input=false",
                    "-lock-timeout=5m",
                    "-detailed-exitcode",
                    "-json",
                    f"-out={plan_file}",
                    f"-var-file={common_tfvars}",
                    f"-var-file={account_config}",
                    f"-var-file={backend_config}",
                ],
                stdout_path=runner_temp / "tofu-plan-ui.jsonl",
                env=process_env,
            )
        if plan_exit in (0, 2):
            show_exit = run_logged(
                ["tofu", f"-chdir={layer_dir}", "show", "-json", str(plan_file)],
                stdout_path=plan_json,
                stderr_path=runner_temp / "tofu-show.log",
                env=process_env,
            )
            if show_exit != 0:
                plan_exit = 1
    except (OSError, ValueError) as error:
        print(f"::error::{error}")
    finally:
        if init_exit != 0:
            failure_stage = "init"
        elif validate_exit != 0:
            failure_stage = "validate"
        elif plan_exit not in (0, 2):
            failure_stage = "plan"
        if failure_stage:
            denied_action = denied_action_from_logs(
                [
                    runner_temp / "tofu-live-init.log",
                    runner_temp / "tofu-live-validate.log",
                    runner_temp / "tofu-plan-ui.jsonl",
                    runner_temp / "tofu-show.log",
                ]
            )
            failure_diagnostic = diagnostic_summary_from_logs(
                [runner_temp / "tofu-plan-ui.jsonl"]
            )
        try:
            plan_report.main(
                [
                    "live",
                    "--layer",
                    layer,
                    "--init-exit",
                    str(init_exit),
                    "--validate-exit",
                    str(validate_exit),
                    "--plan-exit",
                    str(plan_exit),
                    "--plan-json",
                    str(plan_json),
                    "--out-dir",
                    str(report_dir),
                    *(["--failure-stage", failure_stage] if failure_stage else []),
                    *(["--denied-action", denied_action] if denied_action else []),
                    *(["--failure-diagnostic", failure_diagnostic] if failure_diagnostic else []),
                    *_metadata_args(),
                ]
            )
            _summary(report_dir / "summary.md")
        finally:
            for path in (common_tfvars, plan_file, plan_json):
                path.unlink(missing_ok=True)
            shutil.rmtree(runner_temp / "aws", ignore_errors=True)
            for filename in (
                "tofu-live-init.log",
                "tofu-live-validate.log",
                "tofu-plan-ui.jsonl",
                "tofu-show.log",
            ):
                (runner_temp / filename).unlink(missing_ok=True)
            _append(
                os.environ.get("GITHUB_ENV"),
                "AWS_ACCESS_KEY_ID=\nAWS_SECRET_ACCESS_KEY=\nAWS_SESSION_TOKEN=\n",
            )

    if init_exit == 0 and validate_exit == 0 and plan_exit in (0, 2):
        return 0
    print(f"::error::Live OpenTofu init, validate, or plan failed for {layer}")
    return 1


def run_analysis() -> int:
    runner_temp = Path(_required_env("RUNNER_TEMP"))
    try:
        return bedrock_analysis.main(
            [
                "--reviews-dir",
                str(runner_temp / "tofu-plan-poc-reports"),
                "--model-id",
                os.environ.get("MODEL_ID", "us.anthropic.claude-sonnet-4-6"),
                "--region",
                os.environ.get("AWS_REGION", "us-east-1"),
                "--repository",
                os.environ.get("GITHUB_REPOSITORY", "unknown"),
                "--run-id",
                os.environ.get("GITHUB_RUN_ID", "unknown"),
                "--head-sha",
                os.environ.get("HEAD_SHA", "unknown"),
                "--out-json",
                str(runner_temp / "tofu-plan-poc-analysis" / "analysis.json"),
                "--out-markdown",
                str(runner_temp / "tofu-plan-poc-analysis" / "analysis.md"),
            ]
        )
    finally:
        _append(
            os.environ.get("GITHUB_ENV"),
            "AWS_ACCESS_KEY_ID=\nAWS_SECRET_ACCESS_KEY=\nAWS_SESSION_TOKEN=\n",
        )


def run_aggregate() -> int:
    runner_temp = Path(_required_env("RUNNER_TEMP"))
    discovery_path = runner_temp / "tofu-plan-poc-discovery" / "discovery.json"
    reports_dir = runner_temp / "tofu-plan-poc-reports"
    analysis_path = runner_temp / "tofu-plan-poc-analysis" / "analysis.md"
    require_live = os.environ.get("REQUIRE_LIVE") == "true"
    discovery_result = json.loads(discovery_path.read_text(encoding="utf-8"))
    results = aggregate_report.load_results(reports_dir)
    gate, reasons = aggregate_report.aggregate(
        discovery=discovery_result,
        results=results,
        require_live=require_live,
        expected_metadata={
            "repository": os.environ.get("GITHUB_REPOSITORY", "unknown"),
            "head_sha": os.environ.get("HEAD_SHA", "unknown"),
            "run_id": os.environ.get("GITHUB_RUN_ID", "unknown"),
        },
    )
    markdown = aggregate_report.render_markdown(
        discovery=discovery_result,
        results=results,
        gate=gate,
        reasons=reasons,
        require_live=require_live,
        analysis_markdown=(
            analysis_path.read_text(encoding="utf-8") if analysis_path.is_file() else None
        ),
        analysis_status=os.environ.get("ANALYSIS_STATUS", "disabled"),
    )
    summary_path = runner_temp / "tofu-plan-poc-summary.md"
    summary_path.write_text(markdown, encoding="utf-8")
    _summary(summary_path)
    _output("gate", gate)
    if gate == "fail":
        print("::error::One or more expected OpenTofu checks did not complete successfully")
        return 1
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("discover")
    commands.add_parser("analyze")
    commands.add_parser("aggregate")
    for name in ("static", "live"):
        command = commands.add_parser(name)
        command.add_argument("--layer", default="")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if args.command == "discover":
        return run_discovery()
    if args.command == "static":
        return run_static(args.layer or _required_env("LAYER"))
    if args.command == "live":
        return run_live(args.layer or _required_env("LAYER"))
    if args.command == "analyze":
        return run_analysis()
    return run_aggregate()


if __name__ == "__main__":
    raise SystemExit(main())
