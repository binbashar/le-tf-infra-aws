#
# ECR Lifecycle Policy: keep only the latest 20 images (no tag filtering)
#
module "ecr_lifecycle_rule_default_policy_bycount" {
  source = "github.com/binbashar/terraform-aws-ecr-lifecycle-policy-rule.git?ref=1.0.0"

  tag_status   = "any"
  count_type   = "imageCountMoreThan"
  prefixes     = []
  count_number = 20
}

#
# ECR Lifecycle Policy: expire any (no tag filtering) images older than 90 days
#
module "ecr_lifecycle_rule_default_policy_bydate" {
  source = "github.com/binbashar/terraform-aws-ecr-lifecycle-policy-rule.git?ref=1.0.0"

  tag_status   = "any"
  count_type   = "sinceImagePushed"
  prefixes     = []
  count_number = 90
}
