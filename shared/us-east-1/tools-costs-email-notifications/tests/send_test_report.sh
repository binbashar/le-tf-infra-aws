#!/usr/bin/env bash
# Send the monthly cost report to ONE recipient, to review a change in an inbox
# before applying it.
#
# Runs this checkout's src/script.py locally with the deployed Lambda's
# configuration (sender, accounts, tags, credits) and replaces only the
# recipient list. Nothing is deployed and the Lambda is not invoked.
#
# Requirements:
#   - Leverage SSO credentials for the shared account (leverage aws sso login)
#   - uv (https://docs.astral.sh/uv/)
#   - SES in the sandbox: the recipient must be a verified SES identity in the
#     shared account (aws sesv2 create-email-identity --email-identity <email>)
#
# Cost: about two Cost Explorer requests per account (US$0.01 each).
#
# Usage: tests/send_test_report.sh <recipient-email>
#   AWS_PROFILE overrides the profile (default: bb-shared-devops).
set -euo pipefail

RECIPIENT="${1:?usage: $0 <recipient-email>}"
LAYER="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-$HOME/.aws/bb/config}"
export AWS_SHARED_CREDENTIALS_FILE="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/bb/credentials}"
export AWS_PROFILE="${AWS_PROFILE:-bb-shared-devops}"
# Credentials in the environment take precedence over AWS_PROFILE: drop them so
# stale or other-account keys cannot pick the wrong account's function
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# The deployed function's environment, kept in a variable and never printed
ENV_JSON="$(aws lambda get-function-configuration --function-name MonthlyServicesUsage \
  --query 'Environment.Variables' --output json)"

cd "$LAYER/src"
ENV_JSON="$ENV_JSON" RECIPIENT="$RECIPIENT" \
  uv run --no-project --python 3.13 --with boto3 python -I -c '
import json, os, sys
for key, value in json.loads(os.environ["ENV_JSON"]).items():
    if key != "RECIPIENT":
        os.environ[key] = value
sys.dont_write_bytecode = True  # keep __pycache__ out of src/, which is zipped as-is
sys.path.insert(0, ".")
import script
if script.RECIPIENTS != [os.environ["RECIPIENT"]]:
    sys.exit(f"refusing to send: recipients are {script.RECIPIENTS}")
print("Sending only to:", script.RECIPIENTS[0])
body = json.loads(script.lambda_handler({}, None)["body"])
print("Processed accounts:", body["processed_accounts"], "| failed:", ", ".join(body["failed_account_names"]) or "none")
'
