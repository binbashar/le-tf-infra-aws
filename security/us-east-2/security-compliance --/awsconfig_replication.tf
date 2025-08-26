data "aws_s3_bucket" "config_source" {
  count    = var.enable_config_bucket_replication ? 1 : 0
  bucket   = data.terraform_remote_state.config[0].outputs.aws_logs_bucket
  provider = aws.primary
}

resource "aws_s3_bucket" "config_s3_bucket-dr" {
  count  = var.enable_config_bucket_replication ? 1 : 0
  bucket = "${var.project}-${var.environment}-awsconfig-dr"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "config_s3_bucket-dr" {
  count = var.enable_config_bucket_replication ? 1 : 0

  bucket = aws_s3_bucket.config_s3_bucket-dr[0].id

  rule {
    id     = "config-retention"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    expiration {
      days = 730 # 2 years retention for compliance
    }
  }

  rule {
    id     = "config-transitions"
    status = "Enabled"

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

resource "aws_iam_role" "config_replication_role" {
  count = var.enable_config_bucket_replication ? 1 : 0
  name  = "config-replication-role"

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

resource "aws_iam_policy" "config_replication_policy" {
  count = var.enable_config_bucket_replication ? 1 : 0
  name  = "config-replication-policy"

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
        "${data.aws_s3_bucket.config_source[0].arn}"
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
        "${data.aws_s3_bucket.config_source[0].arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.config_s3_bucket-dr[0].arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "config_replication" {
  count      = var.enable_config_bucket_replication ? 1 : 0
  role       = aws_iam_role.config_replication_role[0].name
  policy_arn = aws_iam_policy.config_replication_policy[0].arn
}

resource "aws_s3_bucket_replication_configuration" "config_replication" {
  count  = var.enable_config_bucket_replication ? 1 : 0
  role   = aws_iam_role.config_replication_role[0].arn
  bucket = data.aws_s3_bucket.config_source[0].id

  rule {
    id     = "config"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.config_s3_bucket-dr[0].arn
      storage_class = "STANDARD"
    }
  }

  provider = aws.primary
}
