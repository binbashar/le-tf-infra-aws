#
# Centralized Cloudtrail security bucket policy allowing:
# Services: cloudtrail & config
# Accounts: shared, security and apps-devstg
#
resource "aws_s3_bucket_policy" "cloudtrail_s3_bucket" {
  bucket = module.cloudtrail_s3_bucket.bucket_id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "cloudtrail.amazonaws.com",
                    "config.amazonaws.com"
                ]
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "EnforceSslRequestsOnly",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org",
                "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
EOF
}
