#!/bin/bash
set -e -o pipefail

# Get terraform output and parse terraform output values
TF_BIN="terraform"
TF_OUTPUT=$(cd ../1-prerequisites/ && ${TF_BIN} output -json)
CLUSTER_TEMPLATE="cluster-template.yml"
CLUSTER_FILE="cluster.yml"
SSH_PUBLIC_KEY="$HOME/.ssh/binbash/leverage/devstg-k8s-kops-instances.pub"
CLUSTER_NAME="$(echo ${TF_OUTPUT} | jq -r '.cluster_name.value')"
# kops S3 Bucket state to get the imported cluster.yaml definition
ClUSTER_STATE="s3://$(echo ${TF_OUTPUT} | jq -r '.kops_s3_bucket.value')"

#
# Export a kubecfg file for a cluster from the state store.
# The configuration will be saved into a users $HOME/.kube/config file.
# To export the kubectl configuration to a specific file set the
# KUBECONFIG environment variable.
#
CLUSTER_KUBECONFIG="$HOME/.kube/$CLUSTER_NAME"
export KUBECONFIG="$CLUSTER_KUBECONFIG"

# Export AWS credentials for kops to use them
export AWS_SDK_LOAD_CONFIG=1
export AWS_PROFILE="$(echo ${TF_OUTPUT} | jq -r '.profile.value')"
export AWS_REGION="$(echo ${TF_OUTPUT} | jq -r '.region.value')"
