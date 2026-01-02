#
# VPC Peering:  apps-devstg-dr VPC => Shared DR VPC
#
module "vpc_peering_apps_devstg_dr_to_shared_dr" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v5.1.0"

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
    "Name"             = "${each.key}-to-shared-dr",
    "PeeringRequester" = each.key,
    "PeeringAccepter"  = "shared-dr"
  })
}
