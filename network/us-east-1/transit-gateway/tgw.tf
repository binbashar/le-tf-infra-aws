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

# AWS Transit Gateway
module "tgw" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=v0.12.0"

  count = var.enable_tgw ? 1 : 0
  name  = "${var.project}-${var.environment}-tgw"

  ram_resource_share_enabled = true

  create_transit_gateway                                         = true
  create_transit_gateway_route_table                             = true
  create_transit_gateway_vpc_attachment                          = false
  create_transit_gateway_route_table_association_and_propagation = var.enable_network_firewall ? false : true

  config = merge(
    # network private
    lookup(var.enable_vpc_attach, "network", false) ? {
      for k, v in data.terraform_remote_state.network-vpcs : v.outputs.vpc_id => {
        vpc_id                            = null
        vpc_cidr                          = null
        subnet_ids                        = null
        subnet_route_table_ids            = null
        route_to                          = null
        route_to_cidr_blocks              = []
        transit_gateway_vpc_attachment_id = module.tgw_vpc_attachments_and_subnet_routes_network[k].transit_gateway_vpc_attachment_ids[k]

        static_routes = [
          {
            blackhole              = false
            destination_cidr_block = "0.0.0.0/0"
          }
        ]
      }
    } : {},
    # shared private
    lookup(var.enable_vpc_attach, "shared", false) ? {
      for k, v in data.terraform_remote_state.shared-vpcs : v.outputs.vpc_id => {
        vpc_id                            = null
        vpc_cidr                          = null
        subnet_ids                        = null
        subnet_route_table_ids            = null
        route_to                          = null
        route_to_cidr_blocks              = null
        transit_gateway_vpc_attachment_id = module.tgw_vpc_attachments_and_subnet_routes_shared[k].transit_gateway_vpc_attachment_ids[k]
        static_routes                     = null
      }
    } : {},
  )

  tags = local.tags

  providers = {
    aws = aws.network
  }
}

#
# Route Table definitions
#
module "tgw_inspection_route_table" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=v0.12.0"

  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? 1 : 0

  name = "${var.project}-${var.environment}-inspection"

  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = true
  create_transit_gateway_vpc_attachment                          = false
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    inspection = {
      vpc_id                            = null
      vpc_cidr                          = null
      subnet_ids                        = null
      subnet_route_table_ids            = null
      route_to                          = null
      route_to_cidr_blocks              = null
      transit_gateway_vpc_attachment_id = null
      static_routes = [
        {
          blackhole              = false
          destination_cidr_block = "0.0.0.0/0"
        }
      ]
    }
  }

  tags = local.tags

  providers = {
    aws = aws.network
  }
}

# apps-devstg
module "tgw_apps_devstg_route_table" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=v0.12.0"

  count = var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg", false) ? 1 : 0

  name = "${var.project}-${var.environment}-apps-devstg"

  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = true
  create_transit_gateway_vpc_attachment                          = false
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    apps-devstg = {
      vpc_id                            = null
      vpc_cidr                          = null
      subnet_ids                        = null
      subnet_route_table_ids            = null
      route_to                          = null
      route_to_cidr_blocks              = null
      transit_gateway_vpc_attachment_id = null
      static_routes                     = []
    }
  }

  tags = local.tags

  providers = {
    aws = aws.network
  }
}

# apps-prd
module "tgw_apps_prd_route_table" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=v0.12.0"

  count = var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd", false) ? 1 : 0

  name = "${var.project}-${var.environment}-apps-prd"

  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = true
  create_transit_gateway_vpc_attachment                          = false
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    apps-prd = {
      vpc_id                            = null
      vpc_cidr                          = null
      subnet_ids                        = null
      subnet_route_table_ids            = null
      route_to                          = null
      route_to_cidr_blocks              = null
      transit_gateway_vpc_attachment_id = null
      static_routes                     = []
    }
  }

  tags = local.tags

  providers = {
    aws = aws.network
  }
}

#
# Network Firewall
#
resource "aws_ec2_transit_gateway_route" "inspection_default" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network_firewall["network-firewall"].transit_gateway_vpc_attachment_ids["network-firewall"]
}

resource "aws_ec2_transit_gateway_route" "network_firewall_default" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = module.tgw[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network["network-base"].transit_gateway_vpc_attachment_ids["network-base"]
}

resource "aws_ec2_transit_gateway_route_table_association" "network-inspection-association" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? 1 : 0

  transit_gateway_route_table_id = module.tgw[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network_firewall["network-firewall"].transit_gateway_vpc_attachment_ids["network-firewall"]
}

resource "aws_ec2_transit_gateway_route_table_association" "network-base-association" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? 1 : 0

  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network["network-base"].transit_gateway_vpc_attachment_ids["network-base"]
}

#
# shared
#
resource "aws_ec2_transit_gateway_route_table_association" "shared-rt-associations" {

  for_each = {
    for k, v in data.terraform_remote_state.shared-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "shared", false)
  }

  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_shared[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared-rt-propagations" {
  for_each = {
    for k, v in data.terraform_remote_state.shared-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "shared", false)
  }

  transit_gateway_route_table_id = module.tgw[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_shared[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

#
# apps-devstg
#
resource "aws_ec2_transit_gateway_route_table_association" "apps-devstg-rt-associations" {

  for_each = {
    for k, v in data.terraform_remote_state.apps-devstg-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg", false)
  }

  transit_gateway_route_table_id = module.tgw_apps_devstg_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-devstg[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "apps-devstg-rt-propagations" {
  for_each = {
    for k, v in data.terraform_remote_state.apps-devstg-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg", false)
  }

  transit_gateway_route_table_id = module.tgw[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-devstg[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route" "apps-devstg-routes-to-shared" {
  for_each = {
    for k, v in data.terraform_remote_state.shared-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg", false)
  }

  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_shared[each.key].transit_gateway_vpc_attachment_ids[each.key]
  transit_gateway_route_table_id = module.tgw_apps_devstg_route_table[0].transit_gateway_route_table_id
  destination_cidr_block         = each.value.outputs.vpc_cidr_block
}

resource "aws_ec2_transit_gateway_route" "apps-devstg-routes-default" {
  count = var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg", false) ? 1 : 0

  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network["network-base"].transit_gateway_vpc_attachment_ids["network-base"]
  transit_gateway_route_table_id = module.tgw_apps_devstg_route_table[0].transit_gateway_route_table_id
  destination_cidr_block         = "0.0.0.0/0"
}

# apps-devstg ->apps-devstg-dr
resource "aws_ec2_transit_gateway_route" "apps-devstg-to-apps-devstg-dr" {

  for_each = { for k, v in local.apps-devstg-dr-vpcs : k => v if var.enable_tgw && var.enable_tgw_multi_region && lookup(var.enable_vpc_attach, "apps-devstg", false) && try(data.terraform_remote_state.tgw-dr.outputs.tgw_id != null, false) }

  destination_cidr_block         = data.terraform_remote_state.apps-devstg-dr-vpcs[each.key].outputs.vpc_cidr_block
  transit_gateway_route_table_id = module.tgw_apps_devstg_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment.tgw-dr[0].id, null)
}

# Blackholes
resource "aws_ec2_transit_gateway_route" "apps-devstg-blackholes" {
  for_each = {
    for k, v in var.tgw_cidrs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg", false)
  }
  destination_cidr_block         = each.value
  blackhole                      = true
  transit_gateway_route_table_id = module.tgw_apps_devstg_route_table[0].transit_gateway_route_table_id
}

#
# apps-prd
#
resource "aws_ec2_transit_gateway_route_table_association" "apps-prd-rt-associations" {
  for_each = {
    for k, v in data.terraform_remote_state.apps-prd-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd", false)
  }

  transit_gateway_route_table_id = module.tgw_apps_prd_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-prd[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "apps-prd-rt-propagations" {
  for_each = {
    for k, v in data.terraform_remote_state.apps-prd-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd", false)
  }

  transit_gateway_route_table_id = module.tgw[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-prd[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route" "apps-prd-routes-to-shared" {
  for_each = {
    for k, v in data.terraform_remote_state.shared-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd", false)
  }

  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_shared[each.key].transit_gateway_vpc_attachment_ids[each.key]
  transit_gateway_route_table_id = module.tgw_apps_prd_route_table[0].transit_gateway_route_table_id
  destination_cidr_block         = each.value.outputs.vpc_cidr_block
}

resource "aws_ec2_transit_gateway_route" "apps-prd-routes-default" {
  count = var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd", false) ? 1 : 0

  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network["network-base"].transit_gateway_vpc_attachment_ids["network-base"]
  transit_gateway_route_table_id = module.tgw_apps_prd_route_table[0].transit_gateway_route_table_id
  destination_cidr_block         = "0.0.0.0/0"
}

# apps-prd -> apps-prd-dr
resource "aws_ec2_transit_gateway_route" "apps-prd-to-apps-prd-dr" {

  for_each = { for k, v in local.apps-prd-dr-vpcs : k => v if var.enable_tgw && var.enable_tgw_multi_region && lookup(var.enable_vpc_attach, "apps-prd", false) && try(data.terraform_remote_state.tgw-dr.outputs.tgw_id != null, false) }

  destination_cidr_block         = try(data.terraform_remote_state.apps-prd-dr-vpcs[each.key].outputs.vpc_cidr_block)
  transit_gateway_route_table_id = module.tgw_apps_prd_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_peering_attachment.tgw-dr[0].id, null)
}

# Blackholes
resource "aws_ec2_transit_gateway_route" "apps-prd-blackholes" {
  for_each = {
    for k, v in var.tgw_cidrs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd", false)
  }
  destination_cidr_block         = each.value
  blackhole                      = true
  transit_gateway_route_table_id = module.tgw_apps_prd_route_table[0].transit_gateway_route_table_id
}

####################
# Aditional routes #
####################

# Update Inspection & AWS Network Firewall route tables
data "aws_route_table" "inspection_route_table" {
  for_each = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? {
    for k, v in data.terraform_remote_state.network-firewall.outputs["inspection_subnets"] :
    k => v
  } : {}

  subnet_id = each.value
}

resource "aws_route" "inspection_to_endpoint" {
  for_each = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? {
    for s in data.terraform_remote_state.network-firewall.outputs["sync_states"][0] :
    s["availability_zone"] => s["attachment"]
  } : {}

  route_table_id         = data.aws_route_table.inspection_route_table[each.key].id
  vpc_endpoint_id        = each.value[0]["endpoint_id"]
  destination_cidr_block = "0.0.0.0/0"
}

data "aws_route_table" "network_firewall_route_table" {
  for_each = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? {
    for k, v in data.terraform_remote_state.network-firewall.outputs["network_firewall_subnets"] :
  k => v } : {}

  subnet_id = each.value
}

resource "aws_route" "network_firewall_tgw" {
  for_each = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? {
    for s in data.terraform_remote_state.network-firewall.outputs["sync_states"][0] :
    s["availability_zone"] => s["attachment"]
  } : {}

  route_table_id         = data.aws_route_table.network_firewall_route_table[each.key].id
  transit_gateway_id     = module.tgw[0].transit_gateway_id
  destination_cidr_block = "0.0.0.0/0"
}
