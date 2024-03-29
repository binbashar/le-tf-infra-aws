#
# VPC Peering:  apps-prd base VPC => eks clusters VPC
module "vpc_peering_apps_prd_to_eks_clusters" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v5.0.0"

  for_each = {
    for k, v in local.apps-prd-vpcs :
    k => v if !var.enable_tgw && k != "apps-prd-base" # No peerings when TGW enabled or against the base network
  }

  providers = {
    aws.this = aws
    aws.peer = aws
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
    "Name"             = "apps-prd-to-${each.key}",
    "PeeringRequester" = each.key,
    "PeeringAccepter"  = "apps-prd"
  })
}
