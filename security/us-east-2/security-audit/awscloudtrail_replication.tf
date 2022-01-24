resource "aws_s3_bucket" "cloudtrail_s3_bucket-dr" {
  bucket = "${var.project}-${var.environment}-cloudtrail-org-dr"
}

resource "aws_iam_role" "replication" {
  name = "cloudtrail-replication-role"

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

resource "aws_iam_policy" "cloudtrail-replication-policy" {
  name = "cloudtrail-replication-policy"

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
data "terraform_remote_state" "cloudtrail" {
        "${data.terraform_remote_state.cloudtrail.outputs.bucket_arn}"
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
        "${data.terraform_remote_state.cloudtrail.outputs.bucket_arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.cloudtrail_s3_bucket-dr.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.cloudtrail_replication_role.name
  policy_arn = aws_iam_policy.cloudtrail_replication_policy.arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.source.id

  rule {
    id     = "cloudtrail"
    prefix = "cloudtrail"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.cloudtrail_s3_bucket-dr.arn
      storage_class = "STANDARD"
    }
  }
}
