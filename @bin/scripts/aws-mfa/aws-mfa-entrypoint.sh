#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# - In a nutshell, what the script does is:
# -----------------------------------------------------------------------------
#   1. Figure out all the AWS profiles used by Terraform
#   2. For each profile:
#       2.1. Get the role, MFA serial number, and source profile
#       2.2. Figure out the OTP or prompt the user
#       2.3. Assume the role to create temporary credentials
#       2.4. Generate the AWS profiles config files
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
AWS_CACHE_DIR=`printenv AWS_CACHE_DIR || echo /tmp/cache`
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

# Ensure cache credentials dir exists
mkdir -p $AWS_CACHE_DIR


# -----------------------------------------------------------------------------
# 1. Figure out all the AWS profiles used by Terraform
# -----------------------------------------------------------------------------

# Parse all available profiles in config.tf
set +e
RAW_PROFILES=()
PARSED_PROFILES=`grep -E "^\s+profile" config.tf`
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
    # 2.1. Get the role, serial number and source profile from AWS config file
    # -----------------------------------------------------------------------------
    MFA_ROLE_ARN="$(get_profile $SRC_AWS_CONFIG_FILE $SRC_AWS_SHARED_CREDENTIALS_FILE $i role_arn)"
    debug "MFA_ROLE_ARN=$MFA_ROLE_ARN"
    MFA_SERIAL_NUMBER="$(get_profile $SRC_AWS_CONFIG_FILE $SRC_AWS_SHARED_CREDENTIALS_FILE $i mfa_serial)"
    debug "MFA_SERIAL_NUMBER=$MFA_SERIAL_NUMBER"
    MFA_PROFILE_NAME="$(get_profile $SRC_AWS_CONFIG_FILE $SRC_AWS_SHARED_CREDENTIALS_FILE $i source_profile)"
    debug "MFA_PROFILE_NAME=$MFA_PROFILE_NAME"
    MFA_TOTP_KEY="$(get_profile $SRC_AWS_CONFIG_FILE $SRC_AWS_SHARED_CREDENTIALS_FILE $i totp_key)"
    debug "MFA_TOTP_KEY=$MFA_TOTP_KEY"
    # Validate all required fields
    if [[ $MFA_ROLE_ARN == "" ]]; then error "Missing 'role_arn'" && exit 150; fi
    if [[ $MFA_SERIAL_NUMBER == "" ]]; then error "Missing 'mfa_serial'" && exit 151; fi
    if [[ $MFA_PROFILE_NAME == "" ]]; then error "Missing 'source_profile'" && exit 152; fi

    # -----------------------------------------------------------------------------
    # 2.2. Figure out the OTP or prompt the user
    # -----------------------------------------------------------------------------
    # Loop a predefined number of times in case the OTP becomes invalid between
    # the time it is generated and the time it is provided to the script
    # -----------------------------------------------------------------------------
    MAX_RETRIES=3
    RETRIES_COUNT=0
    OTP_FAILED=true
    MFA_DURATION=3600
    TEMP_FILE="$AWS_CACHE_DIR/$i"
    debug "TEMP_FILE=$TEMP_FILE"

    while [[ $OTP_FAILED == true && $RETRIES_COUNT -lt $MAX_RETRIES ]]; do

        #
        # Check if cached credentials exist: look for a file that correspond to
        #       the current profile
        #
        if [[ -f "$TEMP_FILE" ]]; then
            debug "Found cached credentials in TEMP_FILE=$TEMP_FILE"

            # Get expiration date/timestamp
            EXPIRATION_DATE=`cat $TEMP_FILE | jq .Credentials.Expiration | sed -e 's/"//g' | sed -e 's/T/ /' | sed -e 's/Z//'`
            debug "EXPIRATION_DATE=$EXPIRATION_DATE"
            EXPIRATION_TS=`date -d "$EXPIRATION_DATE" +"%s" || date +"%s"`
            debug "EXPIRATION_TS=$EXPIRATION_TS"

            # Compare current timestamp (plus a margin) with the expiration timestamp
            CURRENT_TS=`date +"%s"`
            CURRENT_TS_PLUS_MARGIN=`echo $(( $CURRENT_TS + (30 * 60) ))`
            debug "CURRENT_TS=$CURRENT_TS"
            debug "CURRENT_TS_PLUS_MARGIN=$CURRENT_TS_PLUS_MARGIN"
            if [[ CURRENT_TS_PLUS_MARGIN -lt $EXPIRATION_TS ]]; then
                info "MFA: Using cached credentials"

                # Pretend the OTP succeeded and exit the while loop
                OTP_FAILED=false
                break
            fi
        fi

        # Let's see if can automatically generate the OTP
        if [[ $MFA_TOTP_KEY != "" ]]; then
            debug "MFA_TOTP_KEY=$MFA_TOTP_KEY"
            MFA_TOKEN_CODE=`oathtool --totp -b $MFA_TOTP_KEY`
        else
            # If the MFA TOTP Key was not found, prompt the user for the MFA Token
            MFA_TOKEN_CODE=```
            read -p "MFA: Please type in your OTP: " TOKEN_CODE;
            echo $TOKEN_CODE
            ```
        fi
        debug "MFA_TOKEN_CODE=$MFA_TOKEN_CODE"

        # -----------------------------------------------------------------------------
        # 2.3. Assume the role to generate the temporary credentials
        # -----------------------------------------------------------------------------
        MFA_ROLE_SESSION_NAME="$MFA_PROFILE_NAME-temp"
        set +e
        MFA_ASSUME_ROLE_OUTPUT=```
        AWS_CONFIG_FILE=$SRC_AWS_CONFIG_FILE; \
        AWS_SHARED_CREDENTIALS_FILE=$SRC_AWS_SHARED_CREDENTIALS_FILE; \
        aws sts assume-role \
        --role-arn $MFA_ROLE_ARN \
        --serial-number $MFA_SERIAL_NUMBER \
        --role-session-name $MFA_ROLE_SESSION_NAME \
        --duration-seconds $MFA_DURATION \
        --token-code $MFA_TOKEN_CODE \
        --profile $MFA_PROFILE_NAME \
        2>&1
        ```
        set -e
        debug "MFA_ASSUME_ROLE_OUTPUT=${MFA_ASSUME_ROLE_OUTPUT:0:20}"

        # Check if STS call failed because of invalid token
        if [[ $MFA_ASSUME_ROLE_OUTPUT == *"invalid MFA"* ]]; then
            OTP_FAILED=true
            info "Unable to get valid credentials. Let's try again..."
        else
            OTP_FAILED=false
            echo "$MFA_ASSUME_ROLE_OUTPUT" > $TEMP_FILE
        fi

        debug "OTP_FAILED=$OTP_FAILED"
        RETRIES_COUNT=$((RETRIES_COUNT+1))
        debug "RETRIES_COUNT=$RETRIES_COUNT"

    done

    # Check if credentials were actually created
    if [[ ! $OTP_FAILED ]]; then
        error "Unable to get valid credentials after $MAX_RETRIES attempts"
        exit 160
    fi

    # -----------------------------------------------------------------------------
    # 2.4. Generate the AWS profiles config files
    # -----------------------------------------------------------------------------

    # Parse id, secret and session from the output above
    AWS_ACCESS_KEY_ID=`cat $TEMP_FILE | jq .Credentials.AccessKeyId | sed -e 's/"//g'`
    AWS_SECRET_ACCESS_KEY=`cat $TEMP_FILE | jq .Credentials.SecretAccessKey | sed -e 's/"//g'`
    AWS_SESSION_TOKEN=`cat $TEMP_FILE | jq .Credentials.SessionToken | sed -e 's/"//g'`
    debug "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:0:4}**************"
    debug "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:0:4}**************"
    debug "AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN:0:4}**************"

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
