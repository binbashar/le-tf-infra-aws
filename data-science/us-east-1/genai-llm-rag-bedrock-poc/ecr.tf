module "ecr_repositories" {

  source = "github.com/binbashar/terraform-aws-ecr.git?ref=v2.2.1"

  #
  # Repository name
  #
  create          = true
  repository_name = "${local.name}-b2chat"

  repository_image_tag_mutability = "MUTABLE"

  #
  # Images Retention: set lifecycle policies
  #
  create_lifecycle_policy     = false
  repository_lifecycle_policy = module.ecr_lifecycle_rule_default_policy_bycount.policy_rule

}

module "ecr_lifecycle_rule_default_policy_bycount" {
  source = "github.com/binbashar/terraform-aws-ecr-lifecycle-policy-rule.git?ref=1.1.0"

  tag_status   = "any"
  count_type   = "imageCountMoreThan"
  prefixes     = []
  count_number = 5
}
