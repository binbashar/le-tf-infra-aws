#
# S3 Bucket Policy
#
data "aws_iam_policy_document" "bucket_policy" {
  #
  # 1st Policy Statement
  dynamic "statement" {
    for_each = local.clients_statement

    content {
      sid = "AllowputObjectOwnerFullControlEncyrpted-${statement.value["folder"]}-${statement.value["user"]}"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${var.accounts.security.id}:user/${statement.value["user"]}"]
      }

      actions = [
        "s3:PutObject",
      ]

      resources = [
        "arn:aws:s3:::${local.bucket_name}/${statement.value["folder"]}/*"
      ]
      #
      # Check for a condition that requires that uploads grant:
      # 1- Full control of the object to the bucket owner (canonical user ID)
      # If your policy has this condition, then the user must upload objects
      # with a command similar to the following:
      #
      # aws s3api put-object --bucket my_bucket --key example-file.txt \
      #--body ~/Documents/example-file.txt
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"

        values = [
          "bucket-owner-full-control",
        ]
      }
      #
      # 2- Only when objects are encrypted by a certain AWS Key Management
      # System (AWS KMS) key
      # If your policy has this condition, then the user must upload objects
      # with a command similar to the following:
      #
      # aws s3api put-object --bucket my_bucket --key example-file.txt \
      #--body ~/Documents/example-file.txt \
      #--ssekms-key-id arn:aws:kms:us-east-1:XXXXXXXX3333:key/*
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"

        values = [
          "${data.terraform_remote_state.keys.outputs.aws_kms_key_arn}",
        ]
      }
    }
  }
  #
  # 2nd Policy Statement
  statement {
    sid = "DevOpsRoleFullAccess"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.appsdevstg_account_id}:role/DevOps"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
  }
  #
  # 3rd Policy Statement
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
      "arn:aws:s3:::${local.bucket_name}/*"
    ]

    #
    # Check for a condition that always requires ssl communications
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

#
# S3 Replica Bucket Policy
#
data "aws_iam_policy_document" "bucket_policy_replica" {
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
      "arn:aws:s3:::${local.bucket_name_replica}/*"
    ]

    #
    # Check for a condition that always requires ssl communications
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

#
# S3 Log Bucket Policy
#
data "aws_iam_policy_document" "log_bucket_policy" {
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
      "arn:aws:s3:::${local.bucket_name}-logs/*"
    ]

    #
    # Check for a condition that always requires ssl communications
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
