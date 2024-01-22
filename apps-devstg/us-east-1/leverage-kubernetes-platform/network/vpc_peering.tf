#
# VPC Peering: apps-prd VPC <=> Shared VPC
#
module "vpc_peering_apps_devstg_lkp_to_shared" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v5.0.0"

  for_each = var.create_peering_to_shared ? data.terraform_remote_state.shared-vpcs : {}


  providers = {
    aws.this = aws
    aws.peer = aws.shared
  }

  this_vpc_id = module.vpc-eks.vpc_id
  peer_vpc_id = each.value.outputs.vpc_id

  this_rts_ids = concat(module.vpc-eks.private_route_table_ids, module.vpc-eks.public_route_table_ids)
  peer_rts_ids = concat(
    each.value.outputs.public_route_table_ids,
    each.value.outputs.private_route_table_ids
  )

  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "${var.environment}-eks-lkp-to-shared",
    "PeeringRequester" = "${var.environment}-eks-lkp",
    "PeeringAccepter"  = each.key
  })
}
