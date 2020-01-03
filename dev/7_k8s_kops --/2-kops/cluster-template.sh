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
