#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset


# ---------------------------
# Helper Functions
# ---------------------------

# A simple logging function
function log {
    echo -e "[$(date +"%m-%d-%y %H:%M:%S")][DEBUG] $*"
}

# Get the value of an entry in a config file
function get_config {
    local config_file=$1
    local config_key=$2
    local config_value=```
grep -oEi "^$config_key.*=.*\"([a-zA-Z0-9\-]+)\"" $config_file \
| grep -oEi "\".+\"" \
| sed 's/\"//g'
```
    echo $config_value
}

# Get the value of an AWS profile attribute
function get_profile {
    local aws_config="$1"
    local aws_credentials="$2"
    local profile_name="$3"
    local profile_key="$4"
    local profile_value=```
AWS_CONFIG_FILE=$aws_config; \
AWS_SHARED_CREDENTIALS_FILE=$aws_credentials; \
aws configure get profile.$profile_name.$profile_key
```
    echo $profile_value
}


# -----------------------------------------------------------------------------
# Initialize variables
# -----------------------------------------------------------------------------
BACKEND_CONFIG_FILE=`printenv BACKEND_CONFIG_FILE`
SRC_AWS_CONFIG_FILE=`printenv SRC_AWS_CONFIG_FILE`
SRC_AWS_SHARED_CREDENTIALS_FILE=`printenv SRC_AWS_SHARED_CREDENTIALS_FILE`
TF_AWS_CONFIG_FILE=`printenv AWS_CONFIG_FILE`
TF_AWS_SHARED_CREDENTIALS_FILE=`printenv AWS_SHARED_CREDENTIALS_FILE`
AWS_OUTPUT=json
log "BACKEND_CONFIG_FILE: $BACKEND_CONFIG_FILE"
log "SRC_AWS_CONFIG_FILE: $SRC_AWS_CONFIG_FILE"
log "SRC_AWS_SHARED_CREDENTIALS_FILE: $SRC_AWS_SHARED_CREDENTIALS_FILE"
log "TF_AWS_CONFIG_FILE: $TF_AWS_CONFIG_FILE"
log "TF_AWS_SHARED_CREDENTIALS_FILE: $TF_AWS_SHARED_CREDENTIALS_FILE"
log "AWS_OUTPUT: $AWS_OUTPUT"


# -----------------------------------------------------------------------------
# Find the profile that Terraform will use from the Terraform config file
# -----------------------------------------------------------------------------
TF_PROFILE_NAME="$(get_config $BACKEND_CONFIG_FILE profile)"
log "PROFILE_NAME: $TF_PROFILE_NAME"
AWS_REGION="$(get_config $BACKEND_CONFIG_FILE region)"
log "AWS_REGION: $AWS_REGION"


# -----------------------------------------------------------------------------
# With that we can get the role, serial number and source profile from the AWS config file
# -----------------------------------------------------------------------------
MFA_ROLE_ARN="$(get_profile $SRC_AWS_CONFIG_FILE $SRC_AWS_SHARED_CREDENTIALS_FILE $TF_PROFILE_NAME role_arn)"
log "MFA_ROLE_ARN: $MFA_ROLE_ARN"
MFA_SERIAL_NUMBER="$(get_profile $SRC_AWS_CONFIG_FILE $SRC_AWS_SHARED_CREDENTIALS_FILE $TF_PROFILE_NAME mfa_serial)"
log "MFA_SERIAL_NUMBER: $MFA_SERIAL_NUMBER"
MFA_PROFILE_NAME="$(get_profile $SRC_AWS_CONFIG_FILE $SRC_AWS_SHARED_CREDENTIALS_FILE $TF_PROFILE_NAME source_profile)"
log "MFA_PROFILE_NAME: $MFA_PROFILE_NAME"
MFA_TOTP_KEY="$(get_profile $SRC_AWS_CONFIG_FILE $SRC_AWS_SHARED_CREDENTIALS_FILE $TF_PROFILE_NAME totp_key)"
log "MFA_TOTP_KEY: $MFA_TOTP_KEY"


#
# Try and get and MFA key from the profile
#
if [[ $MFA_TOTP_KEY != "" ]]; then
    echo "MFA_TOTP_KEY: $MFA_TOTP_KEY"
    MFA_TOKEN_CODE=`oathtool --totp -b $MFA_TOTP_KEY`
else
    # If the MFA TOTP Key was not found, prompt the user for the MFA Token
    MFA_TOKEN_CODE=```
read -p 'Type in your token code: ' TOKEN_CODE
echo $TOKEN_CODE
```
fi
log "MFA_TOKEN_CODE: $MFA_TOKEN_CODE"


# -----------------------------------------------------------------------------
# At this point we are ready to assume the role to generate the temporary credentials
# -----------------------------------------------------------------------------
MFA_ROLE_SESSION_NAME="$MFA_PROFILE_NAME-temp"
MFA_DURATION=900
MFA_ASSUME_ROLE_OUTPUT=```
AWS_CONFIG_FILE=$SRC_AWS_CONFIG_FILE \
AWS_SHARED_CREDENTIALS_FILE=$SRC_AWS_SHARED_CREDENTIALS_FILE \
aws sts assume-role \
  --role-arn $MFA_ROLE_ARN \
  --serial-number $MFA_SERIAL_NUMBER \
  --role-session-name $MFA_ROLE_SESSION_NAME \
  --duration-seconds $MFA_DURATION \
  --token-code $MFA_TOKEN_CODE \
  --profile $MFA_PROFILE_NAME
```
# log "MFA_ASSUME_ROLE_OUTPUT: $MFA_ASSUME_ROLE_OUTPUT"
TEMP_FILE=/tmp/mfa-tmp-credentials
echo "$MFA_ASSUME_ROLE_OUTPUT" > $TEMP_FILE


# -----------------------------------------------------------------------------
# Parse id, secret and session from the output above
# -----------------------------------------------------------------------------
AWS_ACCESS_KEY_ID=`cat $TEMP_FILE | jq .Credentials.AccessKeyId | sed -e 's/"//g'`
AWS_SECRET_ACCESS_KEY=`cat $TEMP_FILE | jq .Credentials.SecretAccessKey | sed -e 's/"//g'`
AWS_SESSION_TOKEN=`cat $TEMP_FILE | jq .Credentials.SessionToken | sed -e 's/"//g'`
log "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:5}*************"
log "AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY:0:5}*************"
log "AWS_SESSION_TOKEN: ${AWS_SESSION_TOKEN:0:5}*************"
rm $TEMP_FILE


# -----------------------------------------------------------------------------
# Create a profile block in the AWS credentials file using the credentials above
# -----------------------------------------------------------------------------
REPLACE_CREDENTIALS=```
AWS_CONFIG_FILE=$TF_AWS_CONFIG_FILE; \
AWS_SHARED_CREDENTIALS_FILE=$TF_AWS_SHARED_CREDENTIALS_FILE; \
aws configure set profile.$TF_PROFILE_NAME.aws_access_key_id $AWS_ACCESS_KEY_ID; \
aws configure set profile.$TF_PROFILE_NAME.aws_secret_access_key $AWS_SECRET_ACCESS_KEY; \
aws configure set profile.$TF_PROFILE_NAME.aws_session_token $AWS_SESSION_TOKEN; \
aws configure set region $AWS_REGION; \
aws configure set output $AWS_OUTPUT
```

exec "$@"