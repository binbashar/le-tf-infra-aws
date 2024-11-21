module "vpc_peering" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v6.0.0"

  for_each = {
    for k, v in local.shared_vpcs_peerings :
    k => v
  }

  providers = {
    aws.this = aws
    aws.peer = aws.shared
  }

  this_vpc_id = module.vpc.vpc_id
  peer_vpc_id = data.terraform_remote_state.shared-vpcs[each.key].outputs.vpc_id

  this_rts_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
  peer_rts_ids = concat(
    data.terraform_remote_state.shared-vpcs[each.key].outputs.public_route_table_ids,
    data.terraform_remote_state.shared-vpcs[each.key].outputs.private_route_table_ids
  )

  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "${each.key}-to-${var.vpc_name_suffix}",
    "PeeringRequester" = each.key,
    "PeeringAccepter"  = "shared"
  })
}

