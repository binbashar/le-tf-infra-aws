#===========================================#
# SSO Groups Data Sources
# Lookup SSO groups for authorization rules
#===========================================#

data "aws_ssoadmin_instances" "this" {
  provider = aws.management
}

# SSO Groups lookup (dynamic based on compliance.sso_groups)
data "aws_identitystore_group" "this" {
  provider = aws.management
  for_each = local.sso_groups

  identity_store_id = try(each.value.identity_store_id, tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0])

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value.group_name
    }
  }
}
