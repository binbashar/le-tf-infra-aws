#
# Groups
#
module "iam_group_auditors" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v2.9.0"
  name = "auditors"

  group_users = [
    module.user_auditor_ci.this_iam_user_name,
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/SecurityAudit",
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
  ]
}

module "iam_group_backup_s3" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-group-with-policies?ref=v2.9.0"
  name = "backup-s3"

  group_users = [
    module.user_backup_s3.this_iam_user_name,
  ]

  custom_group_policies = [
    {
      name   = "AllowS3PutBackup"
      policy = data.aws_iam_policy_document.backup_s3_binbash_gdrive.json
    },
  ]
}

data "aws_iam_policy_document" "backup_s3_binbash_gdrive" {
  statement {
    sid = "ListAllMyBuckets"
    effect = "Allow"
    actions = [
    "s3:ListAllMyBuckets",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::bb-shared-gdrive-backup"]
  }

  statement {
    sid = "PutDeleteBucketObjetc"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::bb-shared-gdrive-backup/*"]
  }
}
