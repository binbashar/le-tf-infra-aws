#
# ECR Life-cycle Policy: only keep the latest 10 tagged images.
#
module "ecr_lifecycle_rule_tagged_dev_image_count_7" {
  source = "git::git@github.com:binbashar/terraform-aws-ecr-lifecycle-policy-rule.git?ref=1.0.0"

  tag_status   = "tagged"
  count_type   = "imageCountMoreThan"
  prefixes     = ["dev"]
  count_number = 10
}

module "ecr_lifecycle_rule_tagged_prd_image_count_7" {
  source = "git::git@github.com:binbashar/terraform-aws-ecr-lifecycle-policy-rule.git?ref=1.0.0"

  tag_status   = "tagged"
  count_type   = "imageCountMoreThan"
  prefixes     = ["prd"]
  count_number = 10
}
