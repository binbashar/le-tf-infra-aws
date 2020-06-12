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

  custom_group_policy_arns = [
    aws_iam_policy.s3_put_gdrive_to_s3_backup.arn
  ]
}
