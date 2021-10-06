# locals {
#   bucket_name = "example-rds-exported-snapshots"
#   tags = {
#     Name        = "example"
#     Terraform   = "true"
#   }
# }

# # -----------------------------------------------------------------------------
# # RDS Export To S3 functions
# # -----------------------------------------------------------------------------
# module "rds_export_to_s3" {
#   source = "../../"

#   # Set a prefix for naming resources
#   prefix = "aurora-mysql"

#   # Which RDS snapshots should be exported?
#   database_name = "example-aurora-mysql-database"

#   # Which RDS snapshots events should be included (RDS Aurora or RDS non-Aurora)?
#   rds_event_id = "RDS-EVENT-0169"

#   # Which bucket will store the exported snapshots?
#   snapshots_bucket_name = module.bucket.s3_bucket_id
#   snapshots_bucket_arn = module.bucket.s3_bucket_arn

#   # Which topic should receive notifications about exported snapshots events?
#   notifications_topic_arn = "arn:aws:sns:us-east-1:000000000000:sns-topic-slack-notifications"

#   # Set the logging level
#   # log_level = "DEBUG"

#   tags = local.tags
# }

# # -----------------------------------------------------------------------------
# # This bucket will be used for storing the exported RDS snapshots.
# # -----------------------------------------------------------------------------
# module "bucket" {
#   source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v2.6.0"

#   bucket        = local.bucket_name
#   acl           = "private"
#   force_destroy = true

#   attach_deny_insecure_transport_policy = true

#   server_side_encryption_configuration = {
#     rule = {
#       apply_server_side_encryption_by_default = {
#         sse_algorithm = "AES256"
#       }
#     }
#   }

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true

#   tags = local.tags
# }
