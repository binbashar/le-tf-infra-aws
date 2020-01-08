#!/bin/bash
set -e -o pipefail

# Get terraform output and parse terraform output values
TF_BIN="terraform12"
TF_OUTPUT=$(cd ../1-prerequisites/ && ${TF_BIN} output -json)
CLUSTER_TEMPLATE="cluster-template.yml"
CLUSTER_FILE="cluster.yml"
SSH_PUBLIC_KEY="$HOME/.ssh/bb-ve/devstg-k8s-instances.pub"
CLUSTER_NAME="$(echo ${TF_OUTPUT} | jq -r '.cluster_name.value')"
ClUSTER_STATE="s3://$(echo ${TF_OUTPUT} | jq -r '.kops_s3_bucket.value')"

# Export AWS credentials for kops to use them
export AWS_SDK_LOAD_CONFIG=1
export AWS_PROFILE="$(echo ${TF_OUTPUT} | jq -r '.profile.value')"
export AWS_REGION="$(echo ${TF_OUTPUT} | jq -r '.region.value')"
