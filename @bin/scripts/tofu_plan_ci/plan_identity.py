"""Resolve the per-account plan role and the per-layer inline session policy.

Each account has one plan role whose permissions are the union of its allowlisted
layers' reads. A job assumes it with an inline session policy that narrows the
state bucket and lock table to that job's own layer, so an approved plan of one
layer cannot read another layer's state. Reads outside the state backend are left
to the role's own policy.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Mapping

ROLE_ARN = re.compile(r"^arn:aws:iam::(?P<account>\d{12}):role/[\w+=,.@/-]{1,512}$")
ACCOUNT_ID = re.compile(r"^\d{12}$")
BACKEND_BLOCK = re.compile(r'backend\s+"s3"\s*\{(?P<body>[^{}]*)\}', re.DOTALL)
BACKEND_KEY = re.compile(r'^\s*key\s*=\s*"(?P<key>[A-Za-z0-9_./-]+)"\s*(?:#.*)?$', re.MULTILINE)
SAFE_VALUE = re.compile(r"^[A-Za-z0-9_.-]+$")
# Inline session policies are limited to 2,048 characters of plaintext.
SESSION_POLICY_LIMIT = 2048


def parse_roles(value: str) -> dict[str, dict[str, str]]:
    """Validate the TOFU_PLAN_ROLES JSON: {account: {role_arn, account_id}}."""

    try:
        roles = json.loads(value)
    except json.JSONDecodeError as error:
        raise ValueError(f"TOFU_PLAN_ROLES is not valid JSON: {error.msg}") from None
    if not isinstance(roles, dict) or not roles:
        raise ValueError("TOFU_PLAN_ROLES must be a non-empty JSON object")
    for account, entry in roles.items():
        if not isinstance(entry, dict) or set(entry) != {"role_arn", "account_id"}:
            raise ValueError(
                f"TOFU_PLAN_ROLES[{account!r}] must contain exactly role_arn and account_id"
            )
        match = ROLE_ARN.match(str(entry["role_arn"]))
        if not match or not ACCOUNT_ID.match(str(entry["account_id"])):
            raise ValueError(f"TOFU_PLAN_ROLES[{account!r}] has a malformed role or account")
        if match.group("account") != entry["account_id"]:
            raise ValueError(f"TOFU_PLAN_ROLES[{account!r}] role is not in its account_id")
    return roles


def backend_state_key(config_tf: str) -> str:
    """Return the state key declared in a layer's partial S3 backend block."""

    block = BACKEND_BLOCK.search(config_tf)
    keys = BACKEND_KEY.findall(block.group("body")) if block else []
    if len(keys) != 1:
        raise ValueError("config.tf must declare exactly one S3 backend key")
    key = keys[0]
    if key.startswith("/") or ".." in key.split("/"):
        raise ValueError(f"unsafe S3 backend key: {key!r}")
    return key


def read_tfvar(path: Path, name: str) -> str:
    """Read a simple quoted string variable from a .tfvars file."""

    pattern = re.compile(rf'^\s*{re.escape(name)}\s*=\s*"(?P<value>[^"]*)"\s*(?:#.*)?$')
    for line in path.read_text(encoding="utf-8").splitlines():
        if match := pattern.match(line):
            value = match.group("value")
            if not SAFE_VALUE.match(value):
                raise ValueError(f"unsafe {name} value in {path}")
            return value
    raise ValueError(f"could not read {name} from {path}")


def session_policy(
    *, bucket: str, table: str, region: str, account_id: str, state_key: str
) -> str:
    """Build a compact session policy that narrows the backend to one layer."""

    bucket_arn = f"arn:aws:s3:::{bucket}"
    table_arn = f"arn:aws:dynamodb:{region}:{account_id}:table/{table}"
    narrowed = ["s3:GetObject", "s3:ListBucket", "dynamodb:DeleteItem",
                "dynamodb:GetItem", "dynamodb:PutItem"]
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            # The role's own policy remains the ceiling for everything else.
            {"Sid": "RolePermissions", "Effect": "Allow", "NotAction": narrowed,
             "Resource": "*"},
            {"Sid": "ObjectsOutsideStateBucket", "Effect": "Allow",
             "Action": ["s3:GetObject", "s3:ListBucket"],
             "NotResource": [bucket_arn, f"{bucket_arn}/*"]},
            {"Sid": "ListOwnState", "Effect": "Allow", "Action": "s3:ListBucket",
             "Resource": bucket_arn,
             "Condition": {"StringEquals": {"s3:prefix": state_key}}},
            {"Sid": "ReadOwnState", "Effect": "Allow", "Action": "s3:GetObject",
             "Resource": f"{bucket_arn}/{state_key}"},
            {"Sid": "ItemsOutsideLockTable", "Effect": "Allow",
             "Action": narrowed[2:], "NotResource": table_arn},
            {"Sid": "OwnLockItems", "Effect": "Allow", "Action": narrowed[2:],
             "Resource": table_arn,
             "Condition": {"ForAllValues:StringEquals": {"dynamodb:LeadingKeys": [
                 f"{bucket}/{state_key}", f"{bucket}/{state_key}-md5"]}}},
        ],
    }
    document = json.dumps(policy, separators=(",", ":"), sort_keys=True)
    if len(document) > SESSION_POLICY_LIMIT:
        raise ValueError(
            f"session policy is {len(document)} characters, above the "
            f"{SESSION_POLICY_LIMIT}-character limit"
        )
    return document


def resolve(workspace: Path, layer: str, roles_value: str) -> Mapping[str, str]:
    """Return the role, account, and session policy for one allowlisted layer."""

    account = layer.split("/", 1)[0]
    roles = parse_roles(roles_value)
    if account not in roles:
        raise ValueError(f"TOFU_PLAN_ROLES has no plan role for account {account!r}")
    entry = roles[account]
    backend_config = workspace / account / "config" / "backend.tfvars"
    state_key = backend_state_key(
        (workspace / layer / "config.tf").read_text(encoding="utf-8")
    )
    return {
        "role_arn": entry["role_arn"],
        "account_id": entry["account_id"],
        "session_policy": session_policy(
            bucket=read_tfvar(backend_config, "bucket"),
            table=read_tfvar(backend_config, "dynamodb_table"),
            region=read_tfvar(backend_config, "region"),
            account_id=entry["account_id"],
            state_key=state_key,
        ),
    }
