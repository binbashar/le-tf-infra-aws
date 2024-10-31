## EXTRA VPC PEERINGS

# If extre peerings are needed create them here
#
# Examples:
#
#module "vpc_peering" {
#  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v6.0.0"
#
#  providers = {
#    aws.this = aws
#    aws.peer = aws.apps-devstg
#  }
#
#  this_vpc_id = module.vpc.vpc_id
#  peer_vpc_id = data.terraform_remote_state.apps-devstg-vpc.outputs.vpc_id
#
#  this_rts_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
#  peer_rts_ids = concat(
#    data.terraform_remote_state.apps-devstg-vpc.outputs.public_route_table_ids,
#    data.terraform_remote_state.apps-devstg-vpc.outputs.private_route_table_ids
#  )
#
#  auto_accept_peering = true
#
#  tags = merge(local.tags, {
#    "Name"             = "eks-tools-to-apps-devstg-eks-base",
#    "PeeringRequester" = "eks-tools",
#    "PeeringAccepter"  = "apps-devstg-eks-base"
#  })
#}
#
#module "vpc_peering_prd" {
#  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v6.0.0"
#
#  providers = {
#    aws.this = aws
#    aws.peer = aws.apps-prd
#  }
#
#  this_vpc_id = module.vpc.vpc_id
#  peer_vpc_id = data.terraform_remote_state.apps-prd-vpc.outputs.vpc_id
#
#  this_rts_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
#  peer_rts_ids = concat(
#    data.terraform_remote_state.apps-prd-vpc.outputs.public_route_table_ids,
#    data.terraform_remote_state.apps-prd-vpc.outputs.private_route_table_ids
#  )
#
#  auto_accept_peering = true
#
#  tags = merge(local.tags, {
#    "Name"             = "eks-tools-to-apps-prd-eks-base",
#    "PeeringRequester" = "eks-tools",
#    "PeeringAccepter"  = "apps-prd-eks-base"
#  })
#}
