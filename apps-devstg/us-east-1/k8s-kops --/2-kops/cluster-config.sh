#!/bin/bash
set -e -o pipefail

#
# Pre-requisites validation
#
KOPS_VER="1.28.4"

if [[ $(kops version | grep ${KOPS_VER}) == *${KOPS_VER}* ]] ; then
    echo "Kops Version ${KOPS_VER}"
else
    echo "ERROR: Kops Version ${KOPS_VER} binary not found in PATH, or is not executable"
    echo ""
    echo "To download locally, run:"
    echo "curl -o kops -LO https://github.com/kubernetes/kops/releases/download/${KOPS_VER}/kops-linux-amd64"
    echo "chmod +x ./kops"
    echo "sudo mv ./kops /usr/local/bin/"
    echo ""
    exit 1
fi

#
# Get terraform output and parse terraform output values
TF_OUTPUT=$(cd ../1-prerequisites/ && leverage tf output -json | sed -E '/(^\[[0-9]|^ +INFO)/d')
VALUES_FILE="values.yaml"
echo ${TF_OUTPUT} > values.yaml
PROJECT_SHORT=$(echo ${TF_OUTPUT} | jq -r '.project_short.value')
ENV=$(echo ${TF_OUTPUT} | jq -r '.environment.value')
CLUSTER_TEMPLATE="cluster-template.yml"
CLUSTER_FILE="cluster.yml"
SSH_PUBLIC_KEY=$(echo ${TF_OUTPUT} | jq -r '.ssh_pub_key_path.value')
CLUSTER_NAME="$(echo ${TF_OUTPUT} | jq -r '.cluster_name.value')"
# kops S3 Bucket state to get the imported cluster.yaml definition
ClUSTER_STATE="s3://$(echo ${TF_OUTPUT} | jq -r '.kops_s3_bucket.value')"

#
# Export a kubecfg file for a cluster from the state store.
# The configuration will be saved into a users $HOME/.kube/config file.
# To export the kubectl configuration to a specific file set the
# KUBECONFIG environment variable.
#
CLUSTER_KUBECONFIG="${HOME}/.kube/${PROJECT_SHORT}/${CLUSTER_NAME}"
export KUBECONFIG="${CLUSTER_KUBECONFIG}"

# Export AWS credentials for kops to use them
export AWS_SDK_LOAD_CONFIG=1
export AWS_SHARED_CREDENTIALS_FILE="${HOME}/.aws/${PROJECT_SHORT}/credentials"
export AWS_CONFIG_FILE="${HOME}/.aws/${PROJECT_SHORT}/config"
export AWS_PROFILE="$(echo ${TF_OUTPUT} | jq -r '.profile.value')"
export AWS_REGION="$(echo ${TF_OUTPUT} | jq -r '.region.value')"
