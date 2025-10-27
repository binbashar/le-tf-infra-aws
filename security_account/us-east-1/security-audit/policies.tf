#
# Centralized Cloudtrail security bucket policy allowing:
# Services: cloudtrail & config
# Accounts: shared, security and apps-devstg
#

#
# NOTE: setting the bucket policy like this creates a conflict as
#  both cloudtrail_s3_bucket module and this resource attempt to
#  modify bucket policy which causes `terraform plan` to report
#  changes everytime the aforementioned policies differ.
#
# resource "aws_s3_bucket_policy" "cloudtrail_s3_bucket" {
#   bucket = module.cloudtrail_s3_bucket.bucket_id

#   policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "AWSCloudTrailAclCheck",
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "cloudtrail.amazonaws.com"
#             },
#             "Action": "s3:GetBucketAcl",
#             "Resource": "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org"
#         },
#         {
#             "Sid": "AWSCloudTrailWrite",
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": [
#                     "cloudtrail.amazonaws.com",
#                     "config.amazonaws.com"
#                 ]
#             },
#             "Action": "s3:PutObject",
#             "Resource": "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/*",
#             "Condition": {
#                 "StringEquals": {
#                     "s3:x-amz-acl": "bucket-owner-full-control"
#                 }
#             }
#         },
#         {
#             "Sid": "EnforceSslRequestsOnly",
#             "Effect": "Deny",
#             "Principal": {
#                 "AWS": "*"
#             },
#             "Action": "s3:*",
#             "Resource": [
#                 "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org",
#                 "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/*"
#             ],
#             "Condition": {
#                 "Bool": {
#                     "aws:SecureTransport": "false"
#                 }
#             }
#         }
#     ]
# }
# EOF
# }

#
# NOTE: this also doesn't work as cloudtrail_s3_bucket module does not
#  support extending the policy of the bucket it creates.
#
# data "aws_iam_policy_document" "cloudtrail_s3_bucket" {
#   statement {
#     sid = "AWSCloudTrailAclCheck"
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["cloudtrail.amazonaws.com"]
#     }
#     actions = ["s3:GetBucketAcl"]
#     resources = [
#       "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org"
#     ]
#   }

#   statement {
#     sid = "AWSCloudTrailWrite"
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = [
#         "cloudtrail.amazonaws.com",
#         "config.amazonaws.com"
#       ]
#     }
#     actions = ["s3:PutObject"]
#     resources = [
#       "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/*"
#     ]
#     condition {
#       test = "StringEquals"
#         variable = "s3:x-amz-acl"
#         values = ["bucket-owner-full-control"]
#     }
#   }

#   statement {
#     sid = "EnforceSslRequestsOnly"
#     effect = "Deny"
#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }
#     actions = ["s3:*"]
#     resources = [
#       "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org",
#       "arn:aws:s3:::${var.project}-${var.environment}-cloudtrail-org/*"
#     ]
#     condition {
#       test = "Bool"
#         variable = "aws:SecureTransport"
#         values = ["false"]
#     }
#   }
# }