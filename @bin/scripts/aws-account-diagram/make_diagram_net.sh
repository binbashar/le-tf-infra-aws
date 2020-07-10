#!/usr/bin/env bash

#==============================================================================#
# AWS IAM profile and account
#==============================================================================#
# NOTE: Uncommet the corresponding VARS for the desired AWS Account
#
# binbash-shared
#
PROJECT="bb"
AWS_ACCOUNT_ENV="shared"
AWS_IAM_PROFILE="${PROJECT}-${AWS_ACCOUNT_ENV}-auditor-ci"
AWS_ACCOUNT_NAME="${PROJECT}-${AWS_ACCOUNT_ENV}"
AWS_ACCOUNT_PEER_NAME_1="aws-apps-devstg"
AWS_ACCOUNT_PEER_CIDR_1="172.18.32.0/20"
AWS_ACCOUNT_PEER_NAME_2="aws-apps-prd"
AWS_ACCOUNT_PEER_CIDR_2="172.18.64.0/20"

# binbash-apps-devstg
#
#AWS_ACCOUNT_ENV="apps-devstg"
#AWS_IAM_PROFILE="${PROJECT}-${AWS_ACCOUNT_ENV}-auditor-ci"
#AWS_ACCOUNT_NAME="${PROJECT}-${AWS_ACCOUNT_ENV}"
#AWS_ACCOUNT_PEER_NAME_1="aws-shared"
#AWS_ACCOUNT_PEER_CIDR_1="172.18.0.0/20"
#AWS_ACCOUNT_PEER_NAME_2="aws-apps-prd"
#AWS_ACCOUNT_PEER_CIDR_2="172.18.64.0/20"

# binbash-apps-prd
#
#AWS_ACCOUNT_ENV="apps-prd"
#AWS_IAM_PROFILE="${PROJECT}-${AWS_ACCOUNT_ENV}-auditor-ci"
#AWS_ACCOUNT_NAME="${PROJECT}-${AWS_ACCOUNT_ENV}"
#AWS_ACCOUNT_PEER_NAME_1="aws-shared"
#AWS_ACCOUNT_PEER_CIDR_1="172.18.0.0/20"
#AWS_ACCOUNT_PEER_NAME_2="aws-apps-devstg"
#AWS_ACCOUNT_PEER_CIDR_2="172.18.32.0/20"

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
# CloudMapper
#==============================================================================#
docker run -it --rm \
    -e AWS_ACCESS_KEY_ID=$aws_access_key_id \
    -e AWS_SECRET_ACCESS_KEY=$aws_secret_access_key \
    -p 0.0.0.0:8080:8000 \
    -v $(pwd)/data:/data \
     binbash/cloudmapper:0.0.1 /bin/bash -c \
"python cloudmapper.py configure add-account --config-file config.json --name ${AWS_ACCOUNT_NAME} --id $aws_account; \
python cloudmapper.py configure add-cidr --config-file config.json --cidr ${AWS_ACCOUNT_PEER_CIDR_1} --name ${AWS_ACCOUNT_PEER_NAME_1}; \
python cloudmapper.py configure add-cidr --config-file config.json --cidr ${AWS_ACCOUNT_PEER_CIDR_2} --name ${AWS_ACCOUNT_PEER_NAME_2}; \
cat config.json; \
python cloudmapper.py collect --account ${AWS_ACCOUNT_NAME} --regions $region; \
python cloudmapper.py prepare --account ${AWS_ACCOUNT_NAME} --regions $region; \
cp /opt/cloudmapper/config.json /data/${AWS_ACCOUNT_NAME}-diagram-config.json; \
cp /opt/cloudmapper/web/data.json /data/${AWS_ACCOUNT_NAME}-diagram-data.json; \
python cloudmapper.py webserver --public"
