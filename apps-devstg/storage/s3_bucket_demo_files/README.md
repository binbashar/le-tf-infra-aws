# apps-devstg storage layer

### Cross-Layer dependencies (IAM + KMS)
- [security/base-identities](https://github.com/binbashar/le-tf-infra-aws/blob/master/security/base-identities/groups.tf#L94)
- [apps-devstg/security-keys](https://github.com/binbashar/le-tf-infra-aws/blob/master/apps-devstg/security-keys/kms.tf#L28)
- [apps-devstg/security-keys-dr](https://github.com/binbashar/le-tf-infra-aws/blob/master/apps-devstg/security-keys-dr/kms.tf)

## PutObject
### :white_check_mark: awscli example usage w/ IAM Security Account User
```shell
AWS_SHARED_CREDENTIALS_FILE="~/.aws/bb/credentials" \
AWS_CONFIG_FILE="~/.aws/bb/config" \
aws s3api put-object \
--profile bb-security-s3-demo \
--bucket bb-apps-devstg-demo-files \
--key demo/test-file.txt \
--body ~/Desktop/test-file.txt \
--server-side-encryption aws:kms \
--ssekms-key-id arn:aws:kms:us-east-1:523857393444:key/63c14fe9-c3e7-4d3d-9856-ce372cf961b7 \
--acl bucket-owner-full-control
```

### :white_check_mark: awscli example usage w/ DevOps Role
```shell
AWS_SHARED_CREDENTIALS_FILE="~/.aws/bb/credentials" \
AWS_CONFIG_FILE="~/.aws/bb/config" \
aws s3api put-object \
--profile bb-apps-devstg-devops \
--bucket bb-apps-devstg-demo-files \
--key demo/test-file.txt \
--body ~/Desktop/test-file.txt \
--server-side-encryption aws:kms \
--ssekms-key-id arn:aws:kms:us-east-1:523857393444:key/63c14fe9-c3e7-4d3d-9856-ce372cf961b7 \
--acl bucket-owner-full-control
```

### :white_check_mark: aws example usage expected output
```shell
{
    "ETag": "\"fb148d1c87abbfd727fb0da4770fe45d\"",
    "ServerSideEncryption": "aws:kms",
    "VersionId": "oeMeYJhUtaggnF_rhZ24ug44VTog2i3A",
    "SSEKMSKeyId": "arn:aws:kms:us-east-1:392609628445:key/df674901-9a54-471c-a03b-65ecab96544a"
}
```

## Check replication

### COMPLETED example
```
AWS_SHARED_CREDENTIALS_FILE="~/.aws/bb/credentials" \
AWS_CONFIG_FILE="~/.aws/bb/config" \
aws s3api head-object \
--profile bb-apps-devstg-devops \
--bucket bb-apps-devstg-demo-files \
--key demo/test-file-1.txt

{
    "AcceptRanges": "bytes",
    "LastModified": "Mon, 26 Oct 2020 14:07:16 GMT",
    "ContentLength": 0,
    "ETag": "\"3b6d15dd42540f8b050e0dd9e298f6f5\"",
    "VersionId": "QUmE2ly4pvYfVgtM4E6cV7_Ex0CwR0g_",
    "ContentType": "binary/octet-stream",
    "ServerSideEncryption": "aws:kms",
    "Metadata": {},
    "SSEKMSKeyId": "arn:aws:kms:us-east-1:523857393444:key/63c14fe9-c3e7-4d3d-9856-ce372cf961b7",
    "ReplicationStatus": "COMPLETED"
}

```
### FAILED example
```shell
AWS_SHARED_CREDENTIALS_FILE="~/.aws/bb/credentials" \
AWS_CONFIG_FILE="~/.aws/bb/config" \
aws s3api head-object \
--profile bb-apps-devstg-devops \
--bucket bb-apps-devstg-demo-files \
--key demo/test-file.txt \

{
    "AcceptRanges": "bytes",
    "LastModified": "Mon, 26 Oct 2020 13:26:17 GMT",
    "ContentLength": 0,
    "ETag": "\"8951bbf7457f007f985cd4ef80e9a8a8\"",
    "VersionId": "zFfFEoKp3ym4gnkfi7GqPHdTMJT1SYTN",
    "ContentType": "binary/octet-stream",
    "ServerSideEncryption": "aws:kms",
    "Metadata": {},
    "SSEKMSKeyId": "arn:aws:kms:us-east-1:523857393444:key/63c14fe9-c3e7-4d3d-9856-ce372cf961b7",
    "ReplicationStatus": "FAILED"
}

```

## Ref Links
#### AWS How it Works + Troubleshoot
- :ledger: https://docs.amazonaws.cn/en_us/AmazonS3/latest/API/API_PutObjectAcl.html
- :ledger: https://aws.amazon.com/premiumsupport/knowledge-center/s3-troubleshoot-403/
- :ledger: https://aws.amazon.com/premiumsupport/knowledge-center/s3-403-upload-bucket/

#### AWS Java SDK
- :blue_book: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-using-java-sdk.html
- :orange_book: https://stackoverflow.com/questions/60778481/aws-java-sdk-requiring-bucket-owner-full-control
    - `PutObjectRequest request = new PutObjectRequest(bucketName, filename, data, metadata).withCannedAcl(CannedAccessControlList.BucketOwnerFullControl);`

#### Terraform Doc Consideration
- :ledger: https://stackoverflow.com/questions/49425791/configuring-source-kms-keys-for-replicating-encrypted-objects
-  *Error:* Error putting S3 replication configuration: InvalidRequest: 
    Replication configuration cannot be applied to an Object Lock enabled bucket
    
   ```terraform
      object_lock_configuration = {
        object_lock_enabled = "Enabled"
        rule = {
          default_retention = {
            mode  = "GOVERNANCE"
            years = 1
          }
        }
      }
    ```

