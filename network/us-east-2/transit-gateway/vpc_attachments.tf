# terraform-aws-transit-gateway - vpc attachments
#
# Each vpc attachment config can contain the following fields:
#
#  vpc_id -  The ID of the VPC for which to create a VPC attachment and route table associations and propagations.
#  vpc_cidr - VPC CIDR block.
#  subnet_route_table_ids - The IDs of the subnet route tables. The route tables are used to add routes to allow traffix from the subnets in one VPC to the other VPC attachments.
#  route_to - A set of names to route traffic from the current environment to the specified environments.
#    Example: ["apps-prd", apps-prd-eks"]. Specify either route_to or route_to_cidr_blocks. route_to_cidr_blocks supersedes route_to.
#  route_to_cidr_blocks - A set of VPC CIDR blocks to route traffic from the current environment to the specified VPC CIDR blocks.
#    Specify either route_to or route_to_cidr_blocks. route_to_cidr_blocks supersedes route_to.
#  static_routes - A list of Transit Gateway static route configurations. Note that static routes have a higher precedence than propagated routes.
#  transit_gateway_vpc_attachment_id - An existing Transit Gateway Attachment ID. If provided, the module will use it instead of creating a new one.

# Network Firewall VPC attachment - Inspection subnets (private)
module "tgw_vpc_attachments_and_subnet_routes_network-firewall-dr" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.6.0"

  for_each = {
    for k, v in {
      "network-firewall-dr" = data.terraform_remote_state.network-firewall-dr
    } :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network-dr", false)
  }

  name = "${var.project}-${each.key}-vpc"

  # network account can access the Transit Gateway in the network: account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw-dr[0].transit_gateway_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false
  vpc_attachment_appliance_mode_support                          = "enable"

  config = {
    (each.key) = {
      vpc_id                            = each.value.outputs.vpc_id
      vpc_cidr                          = each.value.outputs.vpc_cidr_block
      subnet_ids                        = values(each.value.outputs.inspection_subnets-dr)
      subnet_route_table_ids            = values(each.value.outputs.inspection_route_table_ids)
      route_to                          = null
      route_to_cidr_blocks              = null
      static_routes                     = null
      transit_gateway_vpc_attachment_id = null
    }
  }

  tags = local.tags

  providers = {
    aws = aws.network
  }
}

# network VPC attachments (private)
module "tgw_vpc_attachments_and_subnet_routes_network-dr" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.6.0"

  for_each = {
    for k, v in data.terraform_remote_state.network-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "network-dr", false)
  }

  name = "${var.project}-${each.key}-vpc"

  # network account can access the Transit Gateway in the network: account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw-dr[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = module.tgw-dr[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false
  vpc_attachment_appliance_mode_support                          = "enable"

  config = {
    (each.key) = {
      vpc_id                            = each.value.outputs.vpc_id
      vpc_cidr                          = each.value.outputs.vpc_cidr_block
      subnet_ids                        = each.value.outputs.private_subnets
      subnet_route_table_ids            = each.value.outputs.private_route_table_ids
      route_to                          = null
      route_to_cidr_blocks              = null
      static_routes                     = null
      transit_gateway_vpc_attachment_id = null
    }
  }

  tags = local.tags

  providers = {
    aws = aws.network
  }
}

# apps-devstg VPC attachments
module "tgw_vpc_attachments_and_subnet_routes_apps-devstg-dr" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.6.0"

  for_each = {
    for k, v in data.terraform_remote_state.apps-devstg-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg-dr", false)
  }

  name = "${var.project}-${each.key}-vpc"

  # apps-devstg account can access the Transit Gateway in the network account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw-dr[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = var.enable_tgw && var.enable_network_firewall ? module.tgw_vpc_attachments_and_subnet_routes_network-firewall-dr["network-firewall-dr"].transit_gateway_route_table_id : module.tgw-dr[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false
  vpc_attachment_appliance_mode_support                          = "enable"

  config = {
    (each.key) = {
      vpc_id                 = each.value.outputs.vpc_id
      vpc_cidr               = each.value.outputs.vpc_cidr_block
      subnet_ids             = each.value.outputs.private_subnets
      subnet_route_table_ids = each.value.outputs.private_route_table_ids
      route_to               = null
      route_to_cidr_blocks = concat(
        ["0.0.0.0/0"], # twg - Add the default route to target the TGW in apps-devstg's private RTs
        #[for v in values(data.terraform_remote_state.shared-vpcs) : v.outputs.vpc_cidr_block],  # shared - Add shared vpc cidrs to target the TGW in apps-devstg's private RTs
        #[for v in values(data.terraform_remote_state.network-vpcs) : v.outputs.vpc_cidr_block], # network - Add network vpc cidrs to target the TGW in apps-devstg's private RTs
      )
      static_routes                     = null
      transit_gateway_vpc_attachment_id = null
    }
  }

  tags = local.tags

  providers = {
    aws = aws.apps-devstg
  }
}

# apps-prd VPC attachments
module "tgw_vpc_attachments_and_subnet_routes_apps-prd-dr" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.6.0"

  for_each = {
    for k, v in data.terraform_remote_state.apps-prd-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd", false)
  }

  name = "${var.project}-${each.key}-vpc"

  # apps-prd account can access the Transit Gateway in the network account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw-dr[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = var.enable_tgw && var.enable_network_firewall ? module.tgw_inspection_route_table[0].transit_gateway_route_table_id : module.tgw-dr[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false
  vpc_attachment_appliance_mode_support                          = "enable"

  config = {
    (each.key) = {
      vpc_id                 = each.value.outputs.vpc_id
      vpc_cidr               = each.value.outputs.vpc_cidr_block
      subnet_ids             = each.value.outputs.private_subnets
      subnet_route_table_ids = each.value.outputs.private_route_table_ids
      route_to               = null
      route_to_cidr_blocks = concat(
        ["0.0.0.0/0"], # twg - Add the default route to target the TGW in apps-prd's private RTs
        #[for v in values(data.terraform_remote_state.shared-vpcs) : v.outputs.vpc_cidr_block],  # shared - Add shared vpc cidrs to target the TGW in apps-prd's private RTs
        #[for v in values(data.terraform_remote_state.network-vpcs) : v.outputs.vpc_cidr_block], # network - Add network vpc cidrs to target the TGW in apps-prd's private RTs
      )
      static_routes                     = null
      transit_gateway_vpc_attachment_id = null
    }
  }

  tags = local.tags

  providers = {
    aws = aws.apps-prd
  }
}

# shared VPC attachments
module "tgw_vpc_attachments_and_subnet_routes_shared-dr" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.6.0"

  for_each = {
    for k, v in data.terraform_remote_state.shared-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "shared-dr", false)
  }

  name = "${var.project}-${each.key}-vpc"

  # apps-devstg account can access the Transit Gateway in the network account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw-dr[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = var.enable_tgw && lookup(var.enable_vpc_attach, "shared-dr", false) ? try(module.tgw_vpc_attachments_and_subnet_routes_network-firewall-dr["network-firewall-dr"].transit_gateway_route_table_id, null) : module.tgw-dr[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false
  vpc_attachment_appliance_mode_support                          = "enable"

  config = {
    (each.key) = {
      vpc_id                 = each.value.outputs.vpc_id
      vpc_cidr               = each.value.outputs.vpc_cidr_block
      subnet_ids             = each.value.outputs.private_subnets
      subnet_route_table_ids = each.value.outputs.private_route_table_ids
      route_to               = null
      route_to_cidr_blocks = concat(
        ["0.0.0.0/0"], # twg - Add the default route to target the TGW in shared's private RTs
        #[for v in values(data.terraform_remote_state.network-vpcs) : v.outputs.vpc_cidr_block], # network - Add network vpc cidrs to target the TGW in shared's private RTs
      )
      static_routes                     = null
      transit_gateway_vpc_attachment_id = null
    }
  }

  tags = local.tags

  providers = {
    aws = aws.shared
  }
}
