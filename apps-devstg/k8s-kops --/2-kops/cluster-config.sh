#!/bin/bash
set -e -o pipefail

#
# Pre-requisites validation
#
KOPS_VER="1.14.1"

if [[ $(kops version | grep ${KOPS_VER}) == *${KOPS_VER}* ]] ; then
    echo "Kops Version ${KOPS_VER}"
else
    echo "ERROR: Kops Version ${KOPS_VER} binary not found in PATH, or is not executable"
    echo "To download locally, run:"
    echo ""
    echo "curl -o kops -LO https://github.com/kubernetes/kops/releases/download/${KOPS_VER}/kops-linux-amd64"
    echo "chmod +x ./kops"
    echo "sudo mv ./kops /usr/local/bin/"
    exit 1
fi

#
# Get terraform output and parse terraform output values
ENV="apps-devstg"
TF_BIN="terraform12"
TF_OUTPUT=$(cd ../1-prerequisites/ && ${TF_BIN} output -json)
CLUSTER_TEMPLATE="cluster-template.yml"
CLUSTER_FILE="cluster.yml"
SSH_PUBLIC_KEY="$HOME/.ssh/bb-le/${ENV}-k8s-kops-instances.pub"
CLUSTER_NAME="$(echo ${TF_OUTPUT} | jq -r '.cluster_name.value')"
# kops S3 Bucket state to get the imported cluster.yaml definition
ClUSTER_STATE="s3://$(echo ${TF_OUTPUT} | jq -r '.kops_s3_bucket.value')"

#
# Export a kubecfg file for a cluster from the state store.
# The configuration will be saved into a users $HOME/.kube/config file.
# To export the kubectl configuration to a specific file set the
# KUBECONFIG environment variable.
#
CLUSTER_KUBECONFIG="$HOME/.kube/bb-le/$CLUSTER_NAME"
export KUBECONFIG="$CLUSTER_KUBECONFIG"

# Export AWS credentials for kops to use them
export AWS_SDK_LOAD_CONFIG=1
export AWS_PROFILE="$(echo ${TF_OUTPUT} | jq -r '.profile.value')"
export AWS_REGION="$(echo ${TF_OUTPUT} | jq -r '.region.value')"
