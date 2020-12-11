#!/bin/bash

#
# Logging Functions
#
function log() {
    echo "[INFO] $*"
}

function error() {
    echo "[ERROR] $*"
}


#
# Set working directory and repository directory
#
DEBUG=0
CWD=`pwd`
REPO_DIR=`git rev-parse --show-toplevel`
log "CWD=$CWD"
log "REPO_DIR=$REPO_DIR"


#
# Determine account and category names
#
ACCOUNT_NAME="${CWD/$REPO_DIR/}"
IFS='/'
read -ra MATCHING_PIECES <<< "$ACCOUNT_NAME"
ACCOUNT_NAME="${MATCHING_PIECES[1]}"
log "ACCOUNT_NAME: $ACCOUNT_NAME"

CATEGORY_NAME="${MATCHING_PIECES[2]}"
CATEGORY_NAME="${CATEGORY_NAME//[0-9_]/}"
log "CATEGORY_NAME: $CATEGORY_NAME"
IFS=' '
echo ""


# - - - - - - - - - - - - -
# Backend Key Checks
# - - - - - - - - - - - - -
log "Checking if backend key starts with $ACCOUNT_NAME ..."
CHECK_BACKEND_KEY_HAS_ACCOUNT=`grep -r --include="config.tf" --exclude-dir=".terraform" ".*key\s*=\s*\"$ACCOUNT_NAME\/" .`
if [ $? -eq 0 ]; then
    log " -> OK"
else
    error " -> FAILED"
fi

# Remove predefined prefixes in $CATEGORY_NAME
CLEAN_CATEGORY_NAME=`echo $CATEGORY_NAME | sed "s/tool-//"`
log "Checking if backend key starts with $ACCOUNT_NAME and follows with $CLEAN_CATEGORY_NAME ..."
CHECK_BACKEND_KEY_HAS_CATEGORY=`grep -r --include="config.tf" --exclude-dir=".terraform" ".*key\s*=\s*\"$ACCOUNT_NAME\/$CLEAN_CATEGORY_NAME" .`
if [ $? -eq 0 ]; then
    log " -> OK"
else
    error " -> FAILED"
fi


# - - - - - - - - - - - - -
# Backend Config Checks
# - - - - - - - - - - - - -
log "Checking if backend.config profile contains $ACCOUNT_NAME ..."
CONFIG_DIR="../config/"
CHECK_CONFIG_PROFILE=`grep -r --include="backend.config" "profile\s*=\s*.*$ACCOUNT_NAME" $CONFIG_DIR`
if [ $? -eq 0 ]; then
    log " -> OK"
else
    error " -> FAILED"
fi

log "Checking if backend.config bucket contains $ACCOUNT_NAME ..."
CONFIG_DIR="../config/"
CHECK_CONFIG_PROFILE=`grep -r --include="backend.config" "bucket\s*=\s*.*$ACCOUNT_NAME" $CONFIG_DIR`
if [ $? -eq 0 ]; then
    log " -> OK"
else
    error " -> FAILED"
fi

log "Checking if backend.config dynamodb_table contains $ACCOUNT_NAME ..."
CONFIG_DIR="../config/"
CHECK_CONFIG_PROFILE=`grep -r --include="backend.config" "dynamodb_table\s*=\s*.*$ACCOUNT_NAME" $CONFIG_DIR`
if [ $? -eq 0 ]; then
    log " -> OK"
else
    error " -> FAILED"
fi

log "Checking if base.config  contains $ACCOUNT_NAME ..."
CONFIG_DIR="../config/"
CHECK_CONFIG_PROFILE=`grep -r --include="account.config" "environment\s*=\s*\"$ACCOUNT_NAME\"" $CONFIG_DIR`
if [ $? -eq 0 ]; then
    log " -> OK"
else
    error " -> FAILED"
fi
