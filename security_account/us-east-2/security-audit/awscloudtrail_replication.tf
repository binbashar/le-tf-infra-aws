data "aws_s3_bucket" "cloudtrail_source" {
  count    = var.enable_cloudtrail_bucket_replication ? 1 : 0
  bucket   = data.terraform_remote_state.cloudtrail[0].outputs.bucket_id
  provider = aws.primary
}

resource "aws_s3_bucket" "cloudtrail_s3_bucket-dr" {
  count  = var.enable_cloudtrail_bucket_replication ? 1 : 0
  bucket = "${var.project}-${var.environment}-cloudtrail-org-dr"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_s3_bucket-dr" {
  count = var.enable_cloudtrail_bucket_replication ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_s3_bucket-dr[0].id

  rule {
    id     = "cloudtrail-retention"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    expiration {
      days = 730 # 2 year retention for audit compliance
    }
  }

  rule {
    id     = "cloudtrail-transitions"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

resource "aws_iam_role" "cloudtrail_replication_role" {
  count = var.enable_cloudtrail_bucket_replication ? 1 : 0
  name  = "cloudtrail-replication-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "cloudtrail_replication_policy" {
  count = var.enable_cloudtrail_bucket_replication ? 1 : 0
  name  = "cloudtrail-replication-policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${data.aws_s3_bucket.cloudtrail_source[0].arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${data.aws_s3_bucket.cloudtrail_source[0].arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.cloudtrail_s3_bucket-dr[0].arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cloudtrail_replication" {
  count      = var.enable_cloudtrail_bucket_replication ? 1 : 0
  role       = aws_iam_role.cloudtrail_replication_role[0].name
  policy_arn = aws_iam_policy.cloudtrail_replication_policy[0].arn
}

resource "aws_s3_bucket_replication_configuration" "cloudtrail_replication" {
  count  = var.enable_cloudtrail_bucket_replication ? 1 : 0
  role   = aws_iam_role.cloudtrail_replication_role[0].arn
  bucket = data.aws_s3_bucket.cloudtrail_source[0].id

  rule {
    id     = "cloudtrail"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.cloudtrail_s3_bucket-dr[0].arn
      storage_class = "STANDARD"
    }
  }

  provider = aws.primary
}
