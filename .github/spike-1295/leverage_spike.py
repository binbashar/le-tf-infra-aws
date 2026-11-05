"""Throwaway spike for #1295: can `leverage tofu` replace native `tofu` in the plan CI?

Runs against apps-devstg/global/cli-test-layer with the OIDC plan credentials that are
already in the environment. Plan only. Every command's output goes to a file under
RUNNER_TEMP and is never printed: this repository is public. Only exit codes and
allowlisted, identifier-free markers reach the job summary.

This file and its workflow are not meant to be merged.
"""

from __future__ import annotations

import json
import os
import re
import secrets
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, os.environ["TRUSTED_SCRIPTS"])
from tofu_plan_ci import plan_digest  # noqa: E402

ROOT = Path(os.environ["CANDIDATE_ROOT"]).resolve()
LAYER = ROOT / os.environ["LAYER"]
TEMP = Path(os.environ["RUNNER_TEMP"]) / "spike-1295"
TEMP.mkdir(parents=True, exist_ok=True)
ACCOUNT = os.environ["LAYER"].split("/", 1)[0]
COMMON = ROOT / "config" / "common.tfvars"
ACCOUNT_TFVARS = ROOT / ACCOUNT / "config" / "account.tfvars"
BACKEND = ROOT / ACCOUNT / "config" / "backend.tfvars"
BUILD_ENV = ROOT / "build.env"
LAYER_BUILD_ENV = LAYER / "build.env"

# Messages Leverage itself prints. Matching them tells which branch ran without
# echoing anything that could carry an identifier.
MARKERS = {
    "sso-token-missing": "No AWS SSO token found",
    "mfa-profile-missing": "have not been properly configured",
    "aws-config-missing": "No such file or directory",
    "layout-invalid": "Layer configuration doesn't seem to be valid",
    "tofu-unknown-flag": "flag provided but not defined",
}

rows: list[tuple[str, str, str]] = []


def run(name: str, command: list[str], env: dict[str, str] | None = None) -> tuple[int, str]:
    log = TEMP / f"{name}.log"
    with log.open("wb") as out:
        code = subprocess.run(command, cwd=LAYER, env=env, stdout=out, stderr=subprocess.STDOUT).returncode
    text = log.read_text(errors="replace")
    hits = [key for key, needle in MARKERS.items() if needle in text]
    return code, ",".join(hits) or "-"


def record(experiment: str, result: str, note: str = "") -> None:
    rows.append((experiment, result, note))
    print(f"{experiment}: {result} {note}".rstrip())


def write_leverage_profile(profile: str, region: str) -> None:
    """Put the OIDC session where Leverage forces AWS_CONFIG_FILE to point."""
    directory = Path.home() / ".aws" / "bb"
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    (directory / "config").write_text(f"[profile {profile}]\nregion = {region}\n")
    (directory / "credentials").write_text(
        f"[{profile}]\n"
        f"aws_access_key_id = {os.environ['AWS_ACCESS_KEY_ID']}\n"
        f"aws_secret_access_key = {os.environ['AWS_SECRET_ACCESS_KEY']}\n"
        f"aws_session_token = {os.environ['AWS_SESSION_TOKEN']}\n"
    )
    for name in ("config", "credentials"):
        (directory / name).chmod(0o600)


def native_env() -> dict[str, str]:
    env = os.environ.copy()
    directory = Path.home() / ".aws" / "bb"
    env.update(
        AWS_CONFIG_FILE=str(directory / "config"),
        AWS_SHARED_CREDENTIALS_FILE=str(directory / "credentials"),
        AWS_PROFILE=profile,
    )
    return env


def show(plan_file: Path, name: str) -> dict | None:
    out = TEMP / f"{name}.json"
    with out.open("wb") as handle:
        code = subprocess.run(
            ["tofu", "show", "-json", str(plan_file)], cwd=LAYER, env=native_env(), stdout=handle,
            stderr=subprocess.DEVNULL,
        ).returncode
    return json.loads(out.read_text()) if code == 0 else None


COMMON.write_text(os.environ["COMMON_TFVARS"].rstrip("\n") + "\n")
COMMON.chmod(0o600)
profile = re.search(r'^\s*profile\s*=\s*"([A-Za-z0-9_-]+)"', BACKEND.read_text(), re.M).group(1)
write_leverage_profile(profile, os.environ.get("AWS_REGION", "us-east-1"))
var_files = [f"-var-file={p}" for p in (COMMON, ACCOUNT_TFVARS, BACKEND)]
init_args = ["init", "-reconfigure", "-input=false", "-lockfile=readonly", "-no-color"]
plan_args = ["-input=false", "-lock-timeout=5m", "-detailed-exitcode", "-json"]

# A. The repository as it is: sso_enabled = true, MFA_ENABLED=false, no SSO token.
code, hits = run("a-init", ["leverage", "tofu", *init_args[:1], "--skip-validation", *init_args[1:]])
record("A. leverage tofu init, config as committed", f"exit {code}", hits)
code, hits = run("a-plan", ["leverage", "tofu", "plan", *plan_args])
record("A. leverage tofu plan, config as committed", f"exit {code}", hits)

# B. sso_enabled = false (what a CI would have to write), MFA_ENABLED=false unchanged.
COMMON.write_text(re.sub(r"(?m)^(\s*sso_enabled\s*=\s*)true", r"\1false", COMMON.read_text()))
code, hits = run("b-plan", ["leverage", "tofu", "plan", *plan_args])
record("B. plan with sso_enabled=false, MFA_ENABLED=false", f"exit {code}", hits)

# C. Also blank MFA_ENABLED, the only value that skips authentication today.
BUILD_ENV.write_text(re.sub(r"(?m)^MFA_ENABLED=.*$", "MFA_ENABLED=", BUILD_ENV.read_text()))
code, hits = run("c-init", ["leverage", "tofu", "init", "--skip-validation", *init_args[1:]])
record("C. leverage tofu init --skip-validation", f"exit {code}", hits)

lev_plan = TEMP / "leverage.tfplan"
code, hits = run("c-plan", ["leverage", "tofu", "plan", *plan_args, f"-out={lev_plan}"])
record("C. leverage tofu plan -detailed-exitcode", f"exit {code}", hits)

nat_plan = TEMP / "native.tfplan"
with (TEMP / "c-native-plan.log").open("wb") as out:
    native_code = subprocess.run(
        ["tofu", "plan", *plan_args, f"-out={nat_plan}", *var_files],
        cwd=LAYER, env=native_env(), stdout=out, stderr=subprocess.STDOUT,
    ).returncode
record("C. native tofu plan -detailed-exitcode, same inputs", f"exit {native_code}")

lev_json, nat_json = show(lev_plan, "leverage-show"), show(nat_plan, "native-show")
record("C. native tofu show -json on the Leverage plan file", "ok" if lev_json else "failed")
if lev_json and nat_json:
    key = secrets.token_hex(32)
    same = plan_digest.digests_match(plan_digest.plan_digest(lev_json, key), plan_digest.plan_digest(nat_json, key))
    record("C. plan digest, Leverage vs native", "equal" if same else "DIFFERENT")

code, hits = run("c-bogus", ["leverage", "tofu", "plan", "-bogus-flag"])
record("C. leverage tofu plan -bogus-flag (tofu exits 1)", f"exit {code}", hits)

# D. A layer-level build.env from the PR picks the binary.
marker = TEMP / "fake-tofu-ran"
fake = ROOT / ".github" / "spike-1295" / "fake-tofu.sh"
LAYER_BUILD_ENV.write_text(f"TF_BINARY={fake.relative_to(ROOT)}\n")
env = os.environ.copy()
env["SPIKE_MARKER"] = str(marker)
code, _ = run("d-plan", ["leverage", "tofu", "plan", *plan_args], env=env)
LAYER_BUILD_ENV.unlink()
ran = marker.read_text().strip().splitlines() if marker.exists() else []
record("D. layer build.env TF_BINARY=<script in the PR>", f"exit {code}", "; ".join(sorted(set(ran))) or "script did not run")

shutil.rmtree(Path.home() / ".aws" / "bb", ignore_errors=True)
COMMON.unlink()

summary = ["## #1295 spike: `leverage tofu` in the plan CI", "", "| Experiment | Result | Markers / note |", "|---|---|---|"]
summary += [f"| {a} | {b} | {c} |" for a, b, c in rows]
with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as handle:
    handle.write("\n".join(summary) + "\n")
