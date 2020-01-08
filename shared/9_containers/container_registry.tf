#
# ECR Life-cycle Policy: only keep the latest 10 tagged images.
#
module "ecr_lifecycle_rule_tagged_dev_image_count_7" {
  source = "git::git@github.com:binbashar/terraform-aws-ecr-lifecycle-policy-rule.git?ref=0.0.4"

  tag_status   = "tagged"
  count_type   = "imageCountMoreThan"
  prefixes     = ["dev"]
  count_number = 7
}

module "ecr_lifecycle_rule_tagged_prd_image_count_7" {
  source = "git::git@github.com:binbashar/terraform-aws-ecr-lifecycle-policy-rule.git?ref=0.0.4"

  tag_status   = "tagged"
  count_type   = "imageCountMoreThan"
  prefixes     = ["prd"]
  count_number = 7
}

#
# ECR Registry: DevOps Images
#
module "ecr_repo_leverage" {
  source = "git::git@github.com:binbashar/terraform-aws-ecr-cross-account.git?ref=0.1.5"

  namespace = "bb"
  name      = "leverage"

  allowed_read_principals = [
    "arn:aws:iam::${var.shared_account_id}:root",
    "arn:aws:iam::${var.dev_account_id}:root",
  ]

  allowed_write_principals = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
  ]

  lifecycle_policy_rules = [
    "${module.ecr_lifecycle_rule_tagged_dev_image_count_7.policy_rule}",
    "${module.ecr_lifecycle_rule_tagged_prd_image_count_7.policy_rule}",
  ]

  lifecycle_policy_rules_count = 2
}
