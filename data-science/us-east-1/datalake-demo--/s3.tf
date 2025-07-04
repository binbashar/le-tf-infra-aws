module "s3_bucket_data_raw" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v4.2.1"

  bucket        = "${local.name}-data-raw-bucket"
  acl           = null
  force_destroy = true

  attach_policy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "billing-objects"
      enabled = true
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 1825
        # 5 years
      }

      noncurrent_version_expiration = {
        days = 1095
        # 2 years
      }
    },
  ]

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags

  policy = data.aws_iam_policy_document.s3_raw_bucket_policy.json
}

# Add this data source to generate the bucket policy for the Firehose role
data "aws_iam_policy_document" "s3_raw_bucket_policy" {
  statement {
    sid    = "AllowKinesisFirehoseAccess"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      module.s3_bucket_data_raw.s3_bucket_arn,
      "${module.s3_bucket_data_raw.s3_bucket_arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [data.terraform_remote_state.kinesis_stream_apps_devstg.outputs.kinesis_firehose_role_arn]
    }
  }
}

module "s3_bucket_data_processed" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v4.2.1"

  bucket        = "${local.name}-data-processed-bucket"
  acl           = null
  force_destroy = true

  attach_policy = false

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "billing-objects"
      enabled = true
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 1825
        # 5 years
      }

      noncurrent_version_expiration = {
        days = 1095
        # 2 years
      }
    },
  ]

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}