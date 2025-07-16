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
    --values ${VALUES_FILE} \
    --template ${CLUSTER_TEMPLATE} \
    --format-yaml > ${CLUSTER_FILE}

echo "You can see the final template for cluster ${CLUSTER_NAME} in file ${CLUSTER_FILE}."
