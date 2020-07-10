#!/usr/bin/env bash

#
# Local ENV vars
#
LOCAL_OS_USER_ID=$(id -u)
LOCAL_OS_GROUP_ID=$(id -g)

# AWS IAM profile and account
# binbash-shared
#
PROJECT="bb"
AWS_ACCOUNT_ENV="shared"
AWS_IAM_PROFILE="${PROJECT}-${AWS_ACCOUNT_ENV}-auditor-ci"
AWS_ACCOUNT_NAME="${PROJECT}-${AWS_ACCOUNT_ENV}"

# binbash-apps-devstg
#
#AWS_ACCOUNT_ENV="apps-devstg"
#AWS_IAM_PROFILE="${PROJECT}-${AWS_ACCOUNT_ENV}-auditor-ci"
#AWS_ACCOUNT_NAME="${PROJECT}-${AWS_ACCOUNT_ENV}"

# binbash-apps-prd
#
#AWS_ACCOUNT_ENV="apps-prd"
#AWS_IAM_PROFILE="${PROJECT}-${AWS_ACCOUNT_ENV}-auditor-ci"
#AWS_ACCOUNT_NAME="${PROJECT}-${AWS_ACCOUNT_ENV}"

#==============================================================================#
# AWS configure IAM credentials
#==============================================================================#
AWS_SHARED_CREDENTIALS_FILE_VAR="~/.aws/${PROJECT}/credentials"
export AWS_SHARED_CREDENTIALS_FILE=${AWS_SHARED_CREDENTIALS_FILE_VAR}
AWS_CONFIG_FILE_VAR="~/.aws/${PROJECT}/config"
export AWS_CONFIG_FILE=${AWS_CONFIG_FILE_VAR}

aws_access_key_id=$(aws configure get aws_access_key_id --profile ${AWS_IAM_PROFILE})
aws_secret_access_key=$(aws configure get aws_secret_access_key --profile ${AWS_IAM_PROFILE})
region=$(aws configure get default.region --profile ${AWS_IAM_PROFILE})
aws_account=$(aws sts get-caller-identity --profile ${AWS_IAM_PROFILE} | jq -r .Account)

#==============================================================================#
# AWS SecurityViz
#==============================================================================#
docker run -it --rm \
    -p 0.0.0.0:8081:3000 \
    -v $(pwd)/data:/aws-security-viz \
    -e AWS_ACCESS_KEY_ID=$aws_access_key_id \
    -e AWS_SECRET_ACCESS_KEY=$aws_secret_access_key \
    binbash/aws-security-viz:0.0.1

sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./data
mv $(pwd)/data/aws-security-viz.png $(pwd)/data/${AWS_ACCOUNT_NAME}-aws-security-viz.png
