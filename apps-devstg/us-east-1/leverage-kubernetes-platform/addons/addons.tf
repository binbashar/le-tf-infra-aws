################################################################################
# EKS Addons
################################################################################

resource "aws_eks_addon" "this" {
  # Not supported on outposts
  for_each = { for k, v in local.addons_available : k => v if !try(v.before_compute, false) }

  cluster_name = data.terraform_remote_state.cluster.outputs.cluster_name
  addon_name   = try(each.value.name, each.key)

  addon_version            = coalesce(try(each.value.addon_version, null), data.aws_eks_addon_version.this[each.key].version)
  configuration_values     = try(each.value.configuration_values, null)
  preserve                 = try(each.value.preserve, null)
  resolve_conflicts        = try(each.value.resolve_conflicts, "OVERWRITE")
  service_account_role_arn = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }

  tags = local.tags
}

resource "aws_eks_addon" "before_compute" {
  # Not supported on outposts
  for_each = { for k, v in local.addons_available : k => v if try(v.before_compute, false) }

  cluster_name = data.terraform_remote_state.cluster.outputs.cluster_name
  addon_name   = try(each.value.name, each.key)

  addon_version            = coalesce(try(each.value.addon_version, null), data.aws_eks_addon_version.this[each.key].version)
  configuration_values     = try(each.value.configuration_values, null)
  preserve                 = try(each.value.preserve, null)
  resolve_conflicts        = try(each.value.resolve_conflicts, "OVERWRITE")
  service_account_role_arn = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }

  tags = local.tags
}

data "aws_eks_addon_version" "this" {
  for_each = { for k, v in local.addons_available : k => v }

  addon_name         = try(each.value.name, each.key)
  kubernetes_version = data.terraform_remote_state.cluster.outputs.cluster_version
  most_recent        = try(each.value.most_recent, null)
}
