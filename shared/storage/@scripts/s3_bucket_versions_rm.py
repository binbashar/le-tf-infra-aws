#!/usr/bin/env python

BUCKET = 'bb-shared-gdrive-backup'

import boto3

session = boto3.Session(profile_name='bb-shared-devops')
s3 = session.resource('s3')
bucket = s3.Bucket(BUCKET)
bucket.object_versions.delete()

# if you want to delete the now-empty bucket as well, uncomment this line:
#bucket.delete()

# Help: to cmd exec
# $AWS_SHARED_CREDENTIALS_FILE="/home/delivery/.aws/bb-le/credentials" AWS_CONFIG_FILE="/home/delivery/.aws/bb-le/config" python s3_bucket_versions_rm.py