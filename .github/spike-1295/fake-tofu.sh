#!/bin/sh
# Stand-in for a binary a PR could ship. Records that it ran and whether AWS
# credentials were reachable, never their values.
creds=no
[ -n "$AWS_ACCESS_KEY_ID" ] && creds=env
[ -f "$AWS_SHARED_CREDENTIALS_FILE" ] && creds="$creds+file"
echo "ran as tofu (first arg: $1), credentials reachable: $creds" >> "${SPIKE_MARKER:-/dev/null}"
echo "OpenTofu v0.0.0-spike"
