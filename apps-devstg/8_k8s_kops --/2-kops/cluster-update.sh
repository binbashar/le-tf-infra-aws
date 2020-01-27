#!/bin/bash
set -e -o pipefail

#
# Import common cluster config
#
source cluster-config.sh

#
# Create/update the kops manifest from terraform output values
#
kops toolbox template \
    --name ${CLUSTER_NAME} \
    --values <( echo ${TF_OUTPUT}) \
    --template ${CLUSTER_TEMPLATE} \
    --format-yaml > ${CLUSTER_FILE}

set -x

#
# Import the cluster manifest into kops state
#
kops replace \
    -f ${CLUSTER_FILE} \
    --state ${ClUSTER_STATE} \
    --name ${CLUSTER_NAME} \
    --force

#
# Create SSH public key (this is only needed the 1st time but it won't break if ran again)
#
kops create secret \
    --state ${ClUSTER_STATE} \
    --name ${CLUSTER_NAME} \
    -i ${SSH_PUBLIC_KEY} \
    sshpublickey admin

#
# Generate the cluster in terraform format
#
kops update cluster \
    --target terraform \
    --state ${ClUSTER_STATE} \
    --name ${CLUSTER_NAME} \
    --create-kube-config=true \
    --out .

#
# Remove AWS provider block from the generated kubernetes.tf as it is already declared in config.tf
#
awk -v x=""  '/provider[[:space:]]"aws"[[:space:]]+\{/{f=1} !f{print} /}/{print x; f=0}' kubernetes.tf > kubernetes.tf.bak
mv kubernetes.tf.bak kubernetes.tf
