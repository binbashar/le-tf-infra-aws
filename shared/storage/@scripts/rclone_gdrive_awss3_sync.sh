#!/usr/bin/env bash

# ENV VARS
#
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=us-east-1

# LOCAL VARIABLES
#
MAIN_FUNC=$1
PWD=$(pwd)

STORAGE_LOCAL_PATH="/path/for/backup/here"
STORAGE_RCLONE_REMOTE_SRC="binbash-backup-gdrive"
STORAGE_RCLONE_REMOTE_DEST="binbash-backup-awss3"
AWS_S3_BACKUP_BUCKET="bb-shared-gdrive-backup"

# Pre-req rclone install and config
#
echo "========================================================================="
echo " Setting rclone configuration file                                       "
echo "========================================================================="
curl https://rclone.org/install.sh | sudo bash
#rclone config file
#cp ${PWD}/rclone.conf ~/.config/rclone/rclone.conf
echo ""

## GDrive pull
#
function rclone_bb_gdrive_pull(){
  echo "========================================================================="
  echo " List rclone remote storage                                              "
  echo "========================================================================="
    rclone lsd ${STORAGE_RCLONE_REMOTE_SRC}:
  echo "========================================================================="
  echo " GDrive pull to local                                                    "
  echo "========================================================================="
  rclone sync --drive-alternate-export ${STORAGE_RCLONE_REMOTE_SRC}:Binbash \
  ${STORAGE_LOCAL_PATH}
}

## AWS S3 push
#
function rclone_bb_awss3_push(){
  echo "========================================================================="
  echo " List rclone remote storage                                              "
  echo "========================================================================="
  rclone lsd ${STORAGE_RCLONE_REMOTE_DEST}:
  echo "========================================================================="
  echo " Push local to AWS S3                                                    "
  echo "========================================================================="
  rclone sync ${STORAGE_LOCAL_PATH} \
  ${STORAGE_RCLONE_REMOTE_DEST}:${AWS_S3_BACKUP_BUCKET}/Binbash
}

## GDrive to AWS S3 sync
#
function rclone_bb_gdrive_awss3_sync(){
  echo "========================================================================="
  echo " List rclone remote storage                                              "
  echo "========================================================================="
  rclone lsd ${STORAGE_RCLONE_REMOTE_SRC}:
  echo "-------------------------------------------------------------------------"
  rclone lsd ${STORAGE_RCLONE_REMOTE_DEST}:${AWS_S3_BACKUP_BUCKET}
  echo "========================================================================="
  echo " GDrive to AWS S3 sync                                                   "
  echo "========================================================================="
  rclone sync --drive-alternate-export \
  ${STORAGE_RCLONE_REMOTE_SRC}:Binbash \
  ${STORAGE_RCLONE_REMOTE_DEST}:${AWS_S3_BACKUP_BUCKET}/Binbash
}

## Main
$MAIN_FUNC

exit 0
