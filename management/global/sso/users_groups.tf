#------------------------------------------------------------------------------
# Create all users defined in the "users" variable
#------------------------------------------------------------------------------
resource "aws_identitystore_user" "default" {
  for_each = local.users

  identity_store_id = local.identity_store_id

  # Username must match the primary email for this to actually work
  user_name    = each.value["email"]
  display_name = "${each.value["first_name"]} ${each.value["last_name"]}"

  name {
    given_name  = each.value["first_name"]
    family_name = each.value["last_name"]
  }

  emails {
    value   = each.value["email"]
    primary = true
  }
}

#------------------------------------------------------------------------------
# Create all groups defined in the "groups" variable
#------------------------------------------------------------------------------
resource "aws_identitystore_group" "default" {
  for_each = local.groups

  display_name      = each.value["name"]
  description       = each.value["description"]
  identity_store_id = local.identity_store_id
}

#------------------------------------------------------------------------------
# Create all users/groups memberships
#------------------------------------------------------------------------------
resource "aws_identitystore_group_membership" "default" {
  for_each = local.users_groups_membership

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.default[each.value["group"]].group_id
  member_id         = aws_identitystore_user.default[each.value["user"]].user_id
}
