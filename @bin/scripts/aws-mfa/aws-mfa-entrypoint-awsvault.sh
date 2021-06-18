#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# - In a nutshell, what the script does is:
# -----------------------------------------------------------------------------
#   1. Figure out all the AWS profiles used by Terraform
#   2. For each profile:
#       2.1. Call aws-vault to generate temporary credentials for the given profile
#       2.2. Generate the AWS profiles config files
#   3. Pass the control back to the main process (e.g. Terraform)
# -----------------------------------------------------------------------------

set -o errexit
set -o pipefail
set -o nounset


# ---------------------------
# Helper Functions
# ---------------------------

# Simple logging functions
function error { log "[ERROR] $1" 0; }
function info { log "[INFO] $1" 1; }
function debug { log "[DEBUG] $1" 2; }
function log {
    if [[ $MFA_SCRIPT_LOG_LEVEL -gt "$2" ]]; then
        echo -e "[$(date +"%m-%d-%y %H:%M:%S")] $1"
    fi
}

# Get the value of an entry in a config file
function get_config {
    local config_file=$1
    local config_key=$2
    local config_value=```
    grep -oEi "^$config_key\s+=.*\"([a-zA-Z0-9\-]+)\"" $config_file \
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
MFA_SCRIPT_LOG_LEVEL=`printenv MFA_SCRIPT_LOG_LEVEL || echo 2`
BACKEND_CONFIG_FILE=`printenv BACKEND_CONFIG_FILE`
COMMON_CONFIG_FILE=`printenv COMMON_CONFIG_FILE`
SRC_AWS_CONFIG_FILE=`printenv SRC_AWS_CONFIG_FILE`
SRC_AWS_SHARED_CREDENTIALS_FILE=`printenv SRC_AWS_SHARED_CREDENTIALS_FILE`
TF_AWS_CONFIG_FILE=`printenv AWS_CONFIG_FILE`
TF_AWS_SHARED_CREDENTIALS_FILE=`printenv AWS_SHARED_CREDENTIALS_FILE`
AWS_REGION="$(get_config $BACKEND_CONFIG_FILE region)"
AWS_OUTPUT=json
debug "BACKEND_CONFIG_FILE=$BACKEND_CONFIG_FILE"
debug "SRC_AWS_CONFIG_FILE=$SRC_AWS_CONFIG_FILE"
debug "SRC_AWS_SHARED_CREDENTIALS_FILE=$SRC_AWS_SHARED_CREDENTIALS_FILE"
debug "TF_AWS_CONFIG_FILE=$TF_AWS_CONFIG_FILE"
debug "TF_AWS_SHARED_CREDENTIALS_FILE=$TF_AWS_SHARED_CREDENTIALS_FILE"
debug "AWS_REGION=$AWS_REGION"
debug "AWS_OUTPUT=$AWS_OUTPUT"


# -----------------------------------------------------------------------------
# Pre-run Steps
# -----------------------------------------------------------------------------

# Make some pre-validations
if [[ ! -f "$SRC_AWS_CONFIG_FILE" ]]; then
    error "Unable to find 'AWS Config' file in path: $SRC_AWS_CONFIG_FILE"
    exit 90
fi
if [[ ! -f "$SRC_AWS_SHARED_CREDENTIALS_FILE" ]]; then
    error "Unable to find 'AWS Credentials' file in path: $SRC_AWS_SHARED_CREDENTIALS_FILE"
    exit 91
fi


# -----------------------------------------------------------------------------
# 1. Figure out all the AWS profiles used by Terraform
# -----------------------------------------------------------------------------

# Parse all available profiles in config.tf and locals.tf
set +e
RAW_PROFILES=()
# config.tf
PARSED_PROFILES=`grep -v "lookup" config.tf | grep -E "^\s+profile"`
while IFS= read -r line ; do
    RAW_PROFILES+=(`echo $line | sed 's/ //g' | sed 's/[\"\$\{\}]//g'`)
done <<< "$PARSED_PROFILES"

# locals.tf
PARSED_PROFILES=`grep -E "^\s+profile" locals.tf`
while IFS= read -r line ; do
    RAW_PROFILES+=(`echo $line | sed 's/ //g' | sed 's/[\"\$\{\}]//g'`)
done <<< "$PARSED_PROFILES"

# Now we need to replace any placeholders in the profiles
PROFILES=()
for i in "${RAW_PROFILES[@]}" ; do
    PROFILE_VALUE="$(get_config $BACKEND_CONFIG_FILE profile)"
    PROJECT_VALUE="$(get_config $COMMON_CONFIG_FILE project)"
    TMP_PROFILE=`echo $i | sed "s/profile=//" | sed "s/var.profile/${PROFILE_VALUE}/" | sed "s/var.project/${PROJECT_VALUE}/"`
    PROFILES+=("$TMP_PROFILE")
done

# And then we have to remove repeated profiles
UNIQ_PROFILES=($(echo "${PROFILES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
if [[ "${#UNIQ_PROFILES[@]}" -eq 0 ]]; then
    error "Unable to find any profiles in config.tf"
    exit 100
fi
info "MFA: Found ${#UNIQ_PROFILES[@]} profile/s"


# -----------------------------------------------------------------------------
# 2. For each profile:
# -----------------------------------------------------------------------------
for i in "${UNIQ_PROFILES[@]}" ; do
    info "MFA: Attempting to get temporary credentials for profile=$i"

    # -----------------------------------------------------------------------------
    # 2.1. Call aws-vault to generate temporary credentials for the given profile
    # -----------------------------------------------------------------------------
    set +e
    TEMP_FILE=/tmp/mfa-tmp-credentials
    MFA_ASSUME_ROLE_OUTPUT=```
    AWS_CONFIG_FILE=$SRC_AWS_CONFIG_FILE; \
    AWS_SHARED_CREDENTIALS_FILE=$SRC_AWS_SHARED_CREDENTIALS_FILE; \
    AWS_VAULT_BACKEND=file \
    aws-vault exec $i -- env | grep AWS
    2>&1
    ```
    set -e
    debug "MFA_ASSUME_ROLE_OUTPUT=${MFA_ASSUME_ROLE_OUTPUT}"
    echo "$MFA_ASSUME_ROLE_OUTPUT" > $TEMP_FILE

    # -----------------------------------------------------------------------------
    # 2.2. Generate the AWS profiles config files
    # -----------------------------------------------------------------------------

    # Parse id, secret and session from the output above
    AWS_ACCESS_KEY_ID=`cat $TEMP_FILE | grep AWS_ACCESS_KEY_ID | sed -e 's/AWS_ACCESS_KEY_ID=//'`
    AWS_SECRET_ACCESS_KEY=`cat $TEMP_FILE | grep AWS_SECRET_ACCESS_KEY | sed -e 's/AWS_SECRET_ACCESS_KEY=//'`
    AWS_SESSION_TOKEN=`cat $TEMP_FILE | grep AWS_SESSION_TOKEN | sed -e 's/AWS_SESSION_TOKEN=//'`
    debug "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:0:4}**************"
    debug "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:0:4}**************"
    debug "AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN:0:4}**************"
    rm $TEMP_FILE

    # Create a profile block in the AWS credentials file using the credentials above
    REPLACE_CREDENTIALS=```
    AWS_CONFIG_FILE=$TF_AWS_CONFIG_FILE; \
    AWS_SHARED_CREDENTIALS_FILE=$TF_AWS_SHARED_CREDENTIALS_FILE; \
    aws configure set profile.$i.aws_access_key_id $AWS_ACCESS_KEY_ID; \
    aws configure set profile.$i.aws_secret_access_key $AWS_SECRET_ACCESS_KEY; \
    aws configure set profile.$i.aws_session_token $AWS_SESSION_TOKEN; \
    aws configure set region $AWS_REGION; \
    aws configure set output $AWS_OUTPUT
    ```

    info "MFA: Credentials written succesfully!"
done

# -----------------------------------------------------------------------------
# 3. Pass the control back to the main process
# -----------------------------------------------------------------------------
exec "$@"