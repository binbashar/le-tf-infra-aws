locals {
  # ##########################
  # NODE GROUPS
  #
  node_groups_internal = var.create_default_node_groups ? {
    for subnet in var.subnet_ids:
    "ng${trim(subnet, "subnet-")}" => {
        min_size       = var.node_group_min_size,
        max_size       = var.node_group_max_size,
        desired_size   = var.node_group_desired_size,
        instance_types = var.node_group_instance_types,
        capacity_type  = var.node_group_capacity_type,
        subnet_ids     = [subnet]
      }
  } : {}
  node_groups = merge(local.node_groups_internal, var.additional_node_groups)
}
