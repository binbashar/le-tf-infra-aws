

#
# ECR Registry: DevOps Images
#
module "ecr_repo_leverage" {
  source = "github.com/binbashar/terraform-aws-ecr-cross-account.git?ref=1.0.1"

  namespace = "bb"
  name      = "leverage"

  allowed_read_principals = [
    "arn:aws:iam::${var.shared_account_id}:root",
    "arn:aws:iam::${var.appsdevstg_account_id}:root",
  ]

  allowed_write_principals = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
  ]

  lifecycle_policy_rules = [
    "${module.ecr_lifecycle_rule_tagged_dev_image_count_7.policy_rule}",
    "${module.ecr_lifecycle_rule_tagged_prd_image_count_7.policy_rule}",
  ]

  lifecycle_policy_rules_count = 2
  scan_on_pushing              = true
}
