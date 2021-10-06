locals {
  bucket_name      = var.create_query_results_bucket ? "${var.prefix}-${var.bucket_name}" : var.bucket_name
  athena_workgroup = "${var.prefix}-${var.athena_workgroup}"
  athena_database  = replace("${var.athena_database}", "-", "_")
}

# -----------------------------------------------------------------------------
# This bucket will be used to store Athena query results (optional)
# -----------------------------------------------------------------------------
module "bucket" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v2.6.0"

  count         = var.create_query_results_bucket ? 1 : 0
  bucket        = local.bucket_name
  acl           = "private"
  force_destroy = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Athena queries:
#   - create db
#   - create table
#   - create partitions for each given date
#   - create sample (typical) queries?
# -----------------------------------------------------------------------------
# resource "aws_athena_workgroup" "this" {
#   name = "${local.athena_workgroup}"

#   configuration {
#     result_configuration {
#       output_location = "s3://${module.bucket[0].s3_bucket_id}/output/"

#       encryption_configuration {
#         encryption_option = "SSE_S3"
#       }
#     }
#   }
# }

resource "aws_athena_database" "this" {
  name          = local.athena_database
  bucket        = local.bucket_name
  force_destroy = true

  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

resource "aws_athena_named_query" "select_all" {
  name      = "vpc_flow_logs_select_all"
  workgroup = aws_athena_workgroup.this.id
  database  = aws_athena_database.this.name
  query     = <<QUERY
SELECT *
FROM ${aws_athena_database.this.name}
WHERE date = DATE('2020-05-04')
LIMIT 50;
QUERY
}
