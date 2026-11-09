#!/usr/bin/env bash
# Send the monthly cost report to ONE recipient, built from this checkout's
# src/report.py with real Cost Explorer data, without deploying anything.
#
# Requirements:
#   - Leverage SSO credentials for this account (leverage aws sso login)
#   - uv (https://docs.astral.sh/uv/)
#   - In the SES sandbox, the recipient must be under the verified domain
#
# Sender, organization name, budget and untagged tag come from report.auto.tfvars;
# the project and profile from the repository's Leverage configuration.
#
# Cost: about 8 Cost Explorer requests (US$0.01 each).
#
# Usage: tests/send_test_report.sh <recipient-email> [YYYY-MM]
#   Environment overrides: AWS_PROFILE, SENDER, ORGANIZATION_NAME, BUDGET_NAME,
#   UNTAGGED_TAG_KEY.
set -euo pipefail

RECIPIENT="${1:?usage: $0 <recipient-email> [YYYY-MM]}"
MONTH="${2:-}"
LAYER="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$LAYER/../../.." && pwd)"
ACCOUNT="$(basename "$(cd "$LAYER/../.." && pwd)")"

# A string value from a simple `name = "value"` line of a .tfvars file
tfvar() { sed -nE "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"(.*)\"[[:space:]]*$/\1/p" "$2" | head -1; }

PROJECT="$(sed -nE 's/^PROJECT=//p' "$ROOT/build.env" | head -1)"
VARS="$LAYER/report.auto.tfvars"

export AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-$HOME/.aws/$PROJECT/config}"
export AWS_SHARED_CREDENTIALS_FILE="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/$PROJECT/credentials}"
export AWS_PROFILE="${AWS_PROFILE:-$(tfvar profile "$ROOT/$ACCOUNT/config/backend.tfvars")}"
export AWS_DEFAULT_REGION=us-east-1
# Credentials in the environment take precedence over AWS_PROFILE: drop them
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

export RECIPIENTS="$RECIPIENT" BINBASH_RECIPIENTS="" MONTH
export SENDER="${SENDER:-$(tfvar sender "$VARS")}"
export ORGANIZATION_NAME="${ORGANIZATION_NAME:-$(tfvar organization_name "$VARS")}"
export BUDGET_NAME="${BUDGET_NAME-$(tfvar budget_name "$VARS")}"
export UNTAGGED_TAG_KEY="${UNTAGGED_TAG_KEY-$(tfvar untagged_tag_key "$VARS")}"
: "${SENDER:?no sender in report.auto.tfvars}" "${ORGANIZATION_NAME:?no organization_name in report.auto.tfvars}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export ACCOUNT_ID

cd "$LAYER/src"
uv run --no-project --python 3.13 --with boto3 python -I -c '
import json, logging, os, sys
sys.dont_write_bytecode = True  # keep __pycache__ out of src/, which is zipped as-is
sys.path.insert(0, ".")
logging.basicConfig(level=logging.WARNING, format="%(levelname)s %(message)s")
import report
to, cc = report.destinations(report.config_from_env(), __import__("datetime").date.today())
if to != [os.environ["RECIPIENTS"]] or cc:
    sys.exit(f"refusing to send: To {to}, Cc {cc}")
event = {"month": os.environ["MONTH"]} if os.environ["MONTH"] else {}
print("Sending only to:", to[0])
print(json.dumps(report.lambda_handler(event, None)))
'
