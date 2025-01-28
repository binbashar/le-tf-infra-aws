data "aws_caller_identity" "current" {}

# ##############################################################################
#
# STATE
#
# Bucket used to store Kops state
#
resource "aws_s3_bucket" "kops_state" {
  bucket = "${var.project}-state-${replace(local.k8s_cluster_name, ".", "-")}"

  #acl = "private"

  lifecycle {
    prevent_destroy = false
  }

  tags = local.tags
}

resource "aws_s3_bucket_policy" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id
  policy = data.aws_iam_policy_document.kops_bucket_policy.json
}

resource "aws_s3_bucket_versioning" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

#resource "aws_s3_bucket_acl" "kops_state" {
#  bucket = aws_s3_bucket.kops_state.id
#  acl    = "private"
#}

resource "aws_s3_bucket_server_side_encryption_configuration" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#
# S3 State Bucket Policy
#
data "aws_iam_policy_document" "kops_bucket_policy" {
  statement {
    sid = "EnforceSSlRequestsOnly"

    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.kops_state.arn}/*",
    ]

    #
    # Check for a condition that always requires ssl communications
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  statement {
    sid = "AllowPrivate"

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.kops_state.arn}",
      "${aws_s3_bucket.kops_state.arn}/*"
    ]
  }
}
# ##############################################################################
# IRSA
# To use the IRSA bucket you should access policy access to bucket in security-base layer
#
# Bucket used to store Kops irsa
#
resource "aws_s3_bucket" "kops_irsa" {
  count = var.enable_irsa ? 1 : 0

  bucket = "${var.project}-irsa-${replace(local.k8s_cluster_name, ".", "-")}"

  lifecycle {
    prevent_destroy = false
  }

  tags = local.tags
}

resource "aws_s3_bucket_policy" "kops_irsa" {
  count = var.enable_irsa ? 1 : 0

  bucket = aws_s3_bucket.kops_irsa[0].id
  policy = data.aws_iam_policy_document.kops_irsa_bucket_policy[0].json
}

resource "aws_s3_bucket_versioning" "kops_irsa" {
  count = var.enable_irsa ? 1 : 0

  bucket = aws_s3_bucket.kops_irsa[0].id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "kops_irsa" {
  count = var.enable_irsa ? 1 : 0

  bucket = aws_s3_bucket.kops_irsa[0].id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "kops_irsa_bucket_policy" {
  count = var.enable_irsa ? 1 : 0

  statement {
    sid = "EnforceSSlRequestsOnly"

    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.kops_irsa[0].arn}/*",
    ]

    #
    # Check for a condition that always requires ssl communications
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  statement {
    sid = "PublicReadOnly"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.kops_irsa[0].arn}/*",
    ]
  }
}
