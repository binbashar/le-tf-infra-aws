#
# Centralized Cloudtrail security bucket policy allowing:
# Services: cloudtrail & config
# Accounts: shared, security and apps-devstg
#
resource "aws_s3_bucket" "cloudtrail_s3_bucket" {
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
            "Resource": [
                "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/AWSLogs/${var.shared_account_id}/*",
                "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/AWSLogs/${var.security_account_id}/*",
                "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/AWSLogs/${var.appsdevstg_account_id}/*",
                "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/*"
            ],
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
EOF
}


//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Sid": "AWSCloudTrailAclCheck",
//            "Effect": "Allow",
//            "Principal": {
//                "Service": "cloudtrail.amazonaws.com"
//            },
//            "Action": "s3:GetBucketAcl",
//            "Resource": "arn:aws:s3:::bb-security-cloudtrail-org"
//        },
//        {
//            "Sid": "AWSCloudTrailWrite",
//            "Effect": "Allow",
//            "Principal": {
//                "Service": [
//                    "cloudtrail.amazonaws.com",
//                    "config.amazonaws.com"
//                ]
//            },
//            "Action": "s3:PutObject",
//            "Resource": [
//                "arn:aws:s3:::bb-security-cloudtrail-org/AWSLogs/900980591242/*",
//                "arn:aws:s3:::bb-security-cloudtrail-org/AWSLogs/763606934258/*",
//                "arn:aws:s3:::bb-security-cloudtrail-org/AWSLogs/523857393444/*",
//                "arn:aws:s3:::bb-security-cloudtrail-org/*"
//            ],
//            "Condition": {
//                "StringEquals": {
//                    "s3:x-amz-acl": "bucket-owner-full-control"
//                }
//            }
//        }
//    ]
//}
