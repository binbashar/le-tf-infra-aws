#
# Create all repositories from the list of repositories
#
module "ecr_repositories" {
  for_each = local.repository_list

  source = "github.com/binbashar/terraform-aws-ecr-cross-account.git?ref=1.0.1"

  #
  # Repository name
  #
  create         = each.value.create
  namespace      = ""
  name           = each.value.name
  use_namespaces = false

  #
  # Permissions: define read or write access
  #
  allowed_read_principals  = each.value.read_permissions
  allowed_write_principals = each.value.write_permissions

  #
  # Images Retention: set lifecycle policies
  #
  lifecycle_policy_rules       = local.default_lifecycle_policy_rules
  lifecycle_policy_rules_count = length(local.default_lifecycle_policy_rules)

  # Security: whether to scan images upon pushing to repository
  scan_on_pushing = true
}
