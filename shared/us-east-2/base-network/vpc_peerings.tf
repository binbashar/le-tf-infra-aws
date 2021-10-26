#
# VPC Peerings: keep in mind that both sides (requester and accepter) are
# managed from this layer.
# Note: requester is referred to as "this" whereas accepter is the "peer".
#
module "vpc_peerings_shared_to_devstg" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v4.0.1"

  # Pass the AWS providers so that both sides of the peering can be managed
  providers = {
    aws.this = aws
    aws.peer = aws.devstg_eks_dr
  }

  # Loop through all defined peerings
  for_each = { for k, v in local.vpc_peerings_devstg : k => v }

  # Provide the VPCs that will be peered
  this_vpc_id = each.value.this_vpc_id
  peer_vpc_id = each.value.peer_vpc_id

  # Provide the Route Tables that will be updated to route traffic through the peering connection
  this_rts_ids = each.value.this_route_table_ids
  peer_rts_ids = each.value.peer_route_table_ids

  # Automatically accept the peering request from the accepter side
  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "shared-dr-to-devstg-eks-dr",
    "PeeringRequester" = "shared-dr",
    "PeeringAccepter"  = "devstg-eks-dr"
  })
}

module "vpc_peerings_shared_to_shared" {
  source = "github.com/binbashar/terraform-aws-vpc-peering.git?ref=v4.0.1"

  # Pass the AWS providers so that both sides of the peering can be managed
  providers = {
    aws.this = aws
    aws.peer = aws.shared_main
  }

  # Loop through all defined peerings
  for_each = { for k, v in local.vpc_peerings_shared : k => v }

  # Provide the VPCs that will be peered
  this_vpc_id = each.value.this_vpc_id
  peer_vpc_id = each.value.peer_vpc_id

  # Provide the Route Tables that will be updated to route traffic through the peering connection
  this_rts_ids = each.value.this_route_table_ids
  peer_rts_ids = each.value.peer_route_table_ids

  # Automatically accept the peering request from the accepter side
  auto_accept_peering = true

  tags = merge(local.tags, {
    "Name"             = "shared-dr-to-shared",
    "PeeringRequester" = "shared-dr",
    "PeeringAccepter"  = "shared"
  })
}
