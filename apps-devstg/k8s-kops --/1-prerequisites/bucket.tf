#
# Bucket used to store Kops state
#
resource "aws_s3_bucket" "kops_state" {
  bucket = "${var.project}-state-${local.k8s_cluster_name}"
  acl    = "private"
  # force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  replication_configuration {
    role = aws_iam_role.replication.arn

    rules {
      id     = "standard_bucket_replication"
      prefix = ""
      status = "Enabled"

      destination {
        bucket        = aws_s3_bucket.kops_state_replica.arn
        storage_class = "STANDARD"
      }
    }
  }

  tags = local.tags
}

# replica over us-west-2
# replica resource destination
resource "aws_s3_bucket" "kops_state_replica" {
  bucket   = "${var.project}-state-replica-${local.k8s_cluster_name}"
  provider = aws.region_secondary

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}

# replica policy
#
resource "aws_iam_role" "replication" {
  name = "iam-role-bucket-replication"

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

resource "aws_iam_policy" "replication" {
  name = "iam-policy-bucket-replication"

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
        "${aws_s3_bucket.kops_state.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.kops_state.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.kops_state_replica.arn}/*"
    }
  ]
}
POLICY
}

# replica attachment.
#
resource "aws_iam_policy_attachment" "replication" {
  name       = "role-policy-replication"
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}
