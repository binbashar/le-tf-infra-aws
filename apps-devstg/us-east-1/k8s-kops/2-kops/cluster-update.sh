#!/bin/bash
set -e -o pipefail

#
# Import common cluster config
#
echo "Sourcing..."
source cluster-config.sh

#
# Create/update the kops manifest from terraform output values
#
echo "Creating template..."
kops toolbox template \
    --name ${CLUSTER_NAME} \
    --values ${VALUES_FILE} \
    --template ${CLUSTER_TEMPLATE} \
    --format-yaml > ${CLUSTER_FILE}

set -x

#
# Import the cluster manifest into kops S3 remote state
#
echo "Importing manifest into S3..."
kops replace \
    -f ${CLUSTER_FILE} \
    --state ${ClUSTER_STATE} \
    --name ${CLUSTER_NAME} \
    --force

#
# Create SSH public key (this is only needed the 1st time but it won't break if ran again)
#
echo "Creating the secret..."
kops create  \
    --state ${ClUSTER_STATE} \
    --name ${CLUSTER_NAME} \
    sshpublickey \
    --ssh-public-key ${SSH_PUBLIC_KEY}

#
# Generate the cluster in terraform format
#
echo "Generating terraform templates..."
kops update cluster \
    --target terraform \
    --state ${ClUSTER_STATE} \
    --name ${CLUSTER_NAME} \
    --create-kube-config=true \
    --out .

#
# Remove AWS provider block from the generated kubernetes.tf.example as it is already declared in config.tf
#
echo "Processing file..."
input="kubernetes.tf"

remove_block() {
    local block_name="$1"
    local start_pattern="$2"
    local end_pattern="$3"

    awk -v start="$start_pattern" -v end="$end_pattern" '
        $0 ~ start { inside_block = 1; next }
        !inside_block { print }
        $0 ~ end { inside_block = 0 }
    ' "$block_name"
}

remove_block ${input} "^provider \"aws\" {" "^}" > kubernetes.tf.bak
mv kubernetes.tf.bak kubernetes.tf
remove_block ${input} "^terraform {" "^}" > kubernetes.tf.bak
mv kubernetes.tf.bak kubernetes.tf
