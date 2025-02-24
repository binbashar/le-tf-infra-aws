#
# ECR Repositories
#
module "shared_ecr_repositories" {
  source = "github.com/binbashar/terraform-aws-ecr.git?ref=v2.2.1"

  for_each = local.repositories

  repository_name = each.value.name

  repository_image_tag_mutability = lookup(each.value, "image_tag_mutability", "MUTABLE")

  repository_read_access_arns       = each.value.read_access_arns
  repository_read_write_access_arns = each.value.read_write_access_arns

  repository_lifecycle_policy = lookup(each.value, "lifecycle_policy", data.aws_ecr_lifecycle_policy_document.default_lifecycle_policy.json)

  tags = local.tags
}

#
# ECR Global Registry configuration
#
module "shared_ecr_registry" {
  source = "github.com/binbashar/terraform-aws-ecr.git?ref=v2.2.1"

  create_repository = false

  manage_registry_scanning_configuration = true
  registry_scan_type                     = "BASIC"
  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter = [
        {
          filter      = "*"
          filter_type = "WILDCARD"
        }
      ]
    }
  ]

  tags = local.tags
}
