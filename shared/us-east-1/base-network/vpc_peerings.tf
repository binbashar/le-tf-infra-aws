#
# VPC Peering:  apps-devstg VPC <=> Shared VPC
#
module "vpc_peering_apps_devstg_to_shared" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v4.0.1"

  for_each = {
    for k, v in local.apps-devstg-vpcs :
    k => v if var.enable_tgw != true
  }

  providers = {
    aws.this = aws
    aws.peer = aws.apps-devstg
  }

  this_vpc_id = module.vpc.vpc_id
  peer_vpc_id = data.terraform_remote_state.apps-devstg-vpcs[each.key].outputs.vpc_id

  this_rts_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
  peer_rts_ids = concat(
    data.terraform_remote_state.apps-devstg-vpcs[each.key].outputs.public_route_table_ids,
    data.terraform_remote_state.apps-devstg-vpcs[each.key].outputs.private_route_table_ids
  )

  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "${each.key}-to-shared",
    "PeeringRequester" = each.key,
    "PeeringAccepter"  = "shared"
  })
}

#
# VPC Peering:  apps-devstg-dr VPC <=> Shared VPC
#
module "vpc_peering_apps_devstg_dr_to_shared" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v4.0.1"

  for_each = {
    for k, v in local.apps-devstg-dr-vpcs :
    k => v if var.enable_tgw != true
  }

  providers = {
    aws.this = aws
    aws.peer = aws.apps-devstg-dr
  }

  this_vpc_id = module.vpc.vpc_id
  peer_vpc_id = data.terraform_remote_state.apps-devstg-dr-vpcs[each.key].outputs.vpc_id

  this_rts_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
  peer_rts_ids = concat(
    data.terraform_remote_state.apps-devstg-dr-vpcs[each.key].outputs.public_route_table_ids,
    data.terraform_remote_state.apps-devstg-dr-vpcs[each.key].outputs.private_route_table_ids
  )

  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "${each.key}-to-shared",
    "PeeringRequester" = each.key,
    "PeeringAccepter"  = "shared"
  })
}

#
# VPC Peering: apps-prd VPC <=> Shared VPC
#
module "vpc_peering_apps_prd_to_shared" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v4.0.1"

  for_each = {
    for k, v in local.apps-prd-vpcs :
    k => v if var.enable_tgw != true
  }

  providers = {
    aws.this = aws
    aws.peer = aws.apps-prd
  }

  this_vpc_id = module.vpc.vpc_id
  peer_vpc_id = data.terraform_remote_state.apps-prd-vpcs[each.key].outputs.vpc_id

  this_rts_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
  peer_rts_ids = concat(
    data.terraform_remote_state.apps-prd-vpcs[each.key].outputs.public_route_table_ids,
    data.terraform_remote_state.apps-prd-vpcs[each.key].outputs.private_route_table_ids
  )

  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "${each.key}-to-shared",
    "PeeringRequester" = each.key,
    "PeeringAccepter"  = "shared"
  })
}

#
# VPC Peering: apps-prd-dr VPC <=> Shared VPC
#
module "vpc_peering_apps_prd_dr_to_shared" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v4.0.1"

  for_each = {
    for k, v in local.apps-prd-dr-vpcs :
    k => v if var.enable_tgw != true
  }

  providers = {
    aws.this = aws
    aws.peer = aws.apps-prd-dr
  }

  this_vpc_id = module.vpc.vpc_id
  peer_vpc_id = data.terraform_remote_state.apps-prd-dr-vpcs[each.key].outputs.vpc_id

  this_rts_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
  peer_rts_ids = concat(
    data.terraform_remote_state.apps-prd-dr-vpcs[each.key].outputs.public_route_table_ids,
    data.terraform_remote_state.apps-prd-dr-vpcs[each.key].outputs.private_route_table_ids
  )

  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "${each.key}-to-shared",
    "PeeringRequester" = each.key,
    "PeeringAccepter"  = "shared"
  })
}

#
# VPC Peering: Shared DR <=> Shared VPC
#
module "vpc_peering_shared_dr_to_shared" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v4.0.1"

  for_each = {
    for k, v in local.shared-dr-vpcs :
    k => v if var.enable_tgw != true
  }

  providers = {
    aws.this = aws
    aws.peer = aws.shared-dr
  }

  this_vpc_id = module.vpc.vpc_id
  peer_vpc_id = data.terraform_remote_state.shared-dr-vpcs[each.key].outputs.vpc_id

  this_rts_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
  peer_rts_ids = concat(
    data.terraform_remote_state.shared-dr-vpcs[each.key].outputs.public_route_table_ids,
    data.terraform_remote_state.shared-dr-vpcs[each.key].outputs.private_route_table_ids
  )

  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "${each.key}-to-shared",
    "PeeringRequester" = each.key,
    "PeeringAccepter"  = "shared"
  })
}
