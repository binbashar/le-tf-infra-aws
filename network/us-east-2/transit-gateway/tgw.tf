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
module "tgw-dr" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  count = var.enable_tgw ? 1 : 0
  name  = "${var.project}-${var.environment}-tgw-dr"

  ram_resource_share_enabled = true

  create_transit_gateway                                         = true
  create_transit_gateway_route_table                             = true
  create_transit_gateway_vpc_attachment                          = false
  create_transit_gateway_route_table_association_and_propagation = var.enable_network_firewall ? false : true

  config = merge(
    # network-dr private
    lookup(var.enable_vpc_attach, "network-dr", false) ? {
      for k, v in data.terraform_remote_state.network-dr-vpcs : v.outputs.vpc_id => {
        vpc_id                            = null
        vpc_cidr                          = null
        subnet_ids                        = null
        subnet_route_table_ids            = null
        route_to                          = null
        route_to_cidr_blocks              = []
        transit_gateway_vpc_attachment_id = module.tgw_vpc_attachments_and_subnet_routes_network-dr[k].transit_gateway_vpc_attachment_ids[k]

        static_routes = [
          {
            blackhole              = false
            destination_cidr_block = "0.0.0.0/0"
          }
        ]
      }
    } : {},
    # shared-dr private
    lookup(var.enable_vpc_attach, "shared-dr", false) ? {
      for k, v in data.terraform_remote_state.shared-dr-vpcs : v.outputs.vpc_id => {
        vpc_id                            = null
        vpc_cidr                          = null
        subnet_ids                        = null
        subnet_route_table_ids            = null
        route_to                          = null
        route_to_cidr_blocks              = null
        transit_gateway_vpc_attachment_id = module.tgw_vpc_attachments_and_subnet_routes_shared-dr[k].transit_gateway_vpc_attachment_ids[k]
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

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network-dr", false) ? 1 : 0

  name = "${var.project}-${var.environment}-inspection"

  existing_transit_gateway_id                                    = module.tgw-dr[0].transit_gateway_id
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
module "tgw_apps_devstg_dr_route_table" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  count = var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg-dr", false) ? 1 : 0

  name = "${var.project}-${var.environment}-apps-devstg-dr"

  existing_transit_gateway_id                                    = module.tgw-dr[0].transit_gateway_id
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
module "tgw_apps_prd_dr_route_table" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  count = var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd-dr", false) ? 1 : 0

  name = "${var.project}-${var.environment}-apps-prd-dr"

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
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network-dr", false) ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network-firewall-dr["network-firewall-dr"].transit_gateway_vpc_attachment_ids["network-firewall-dr"]
}

resource "aws_ec2_transit_gateway_route" "network_firewall_default" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network-dr", false) ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network-dr["network-base-dr"].transit_gateway_vpc_attachment_ids["network-base-dr"]
}

resource "aws_ec2_transit_gateway_route_table_association" "network-inspection-association" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network-dr", false) ? 1 : 0

  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network-firewall-dr["network-firewall-dr"].transit_gateway_vpc_attachment_ids["network-firewall-dr"]
}

resource "aws_ec2_transit_gateway_route_table_association" "network-base-association" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network-dr", false) ? 1 : 0

  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network-dr["network-base-dr"].transit_gateway_vpc_attachment_ids["network-base-dr"]
}

# shared-dr
resource "aws_ec2_transit_gateway_route_table_association" "shared-dr-rt-associations" {

  for_each = {
    for k, v in data.terraform_remote_state.shared-dr-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "shared-dr", false)
  }

  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_shared-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared-dr-rt-propagations" {
  for_each = {
    for k, v in data.terraform_remote_state.shared-dr-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "shared-dr", false)
  }

  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_shared-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]

}

#
# apps-devstg-dr
#
resource "aws_ec2_transit_gateway_route_table_association" "apps-devstg-dr-rt-associations" {

  for_each = {
    for k, v in data.terraform_remote_state.apps-devstg-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg-dr", false)
  }

  transit_gateway_route_table_id = module.tgw_apps_devstg_dr_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-devstg-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "apps-devstg-dr-rt-propagations" {
  for_each = {
    for k, v in data.terraform_remote_state.apps-devstg-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg-dr", false)
  }

  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-devstg-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]

}

resource "aws_ec2_transit_gateway_route" "apps-devstg-dr-routes-to-shared-dr" {
  for_each = {
    for k, v in data.terraform_remote_state.shared-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg-dr", false)
  }

  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_shared-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]
  transit_gateway_route_table_id = module.tgw_apps_devstg_route_dr_table[0].transit_gateway_route_table_id
  destination_cidr_block         = each.value.outputs.vpc_cidr_block
}

resource "aws_ec2_transit_gateway_route" "apps-devstg-dr-routes-default" {
  count = var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg-dr", false) ? 1 : 0

  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network["network-base-dr"].transit_gateway_vpc_attachment_ids["network-base-dr"]
  transit_gateway_route_table_id = module.tgw_apps_devstg_dr_route_table[0].transit_gateway_route_table_id
  destination_cidr_block         = "0.0.0.0/0"
}

# Blackholes
resource "aws_ec2_transit_gateway_route" "apps-devstg-dr-blackholes" {
  for_each = {
    for k, v in var.tgw_cidrs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg-dr", false)
  }
  destination_cidr_block         = each.value
  blackhole                      = true
  transit_gateway_route_table_id = module.tgw_apps_devstg_dr_route_table[0].transit_gateway_route_table_id
}

#
# apps-prd-dr
#
resource "aws_ec2_transit_gateway_route_table_association" "apps-prd-dr-rt-associations" {

  for_each = {
    for k, v in data.terraform_remote_state.apps-prd-dr-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "apps-prd-dr", false)
  }

  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-prd-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "apps-prd-dr-rt-propagations" {
  for_each = {
    for k, v in data.terraform_remote_state.apps-prd-dr-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "apps-prd-dr", false)
  }

  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-prd-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route" "apps-prd-dr-routes-to-shared-dr" {
  for_each = {
    for k, v in data.terraform_remote_state.shared-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd-dr", false)
  }

  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_shared-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]
  transit_gateway_route_table_id = module.tgw_apps_prd_dr_route_table[0].transit_gateway_route_table_id
  destination_cidr_block         = each.value.outputs.vpc_cidr_block
}

resource "aws_ec2_transit_gateway_route" "apps-prd-dr-routes-default" {
  count = var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd-dr", false) ? 1 : 0

  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network["network-base-dr"].transit_gateway_vpc_attachment_ids["network-base-dr"]
  transit_gateway_route_table_id = module.tgw_apps_prd_route_table[0].transit_gateway_route_table_id
  destination_cidr_block         = "0.0.0.0/0"
}

# Blackholes
resource "aws_ec2_transit_gateway_route" "apps-prd-dr-blackholes" {
  for_each = {
    for k, v in var.tgw_cidrs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd-dr", false)
  }
  destination_cidr_block         = each.value
  blackhole                      = true
  transit_gateway_route_table_id = module.tgw_apps_prd_dr_route_table[0].transit_gateway_route_table_id
}

####################
# Aditional routes #
####################

# Update Inspection & AWS Network Firewall route tables
data "aws_route_table" "inspection_route_table" {
  for_each = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network-dr", false) ? {
    for k, v in data.terraform_remote_state.network-firewall-dr.outputs["inspection_subnets-dr"] :
    k => v
  } : {}

  subnet_id = each.value
}

resource "aws_route" "inspection_to_endpoint" {
  for_each = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network-dr", false) ? {
    for s in data.terraform_remote_state.network-firewall-dr.outputs["sync_states"][0] :
    s["availability_zone"] => s["attachment"]
  } : {}

  route_table_id         = data.aws_route_table.inspection_route_table[each.key].id
  vpc_endpoint_id        = each.value[0]["endpoint_id"]
  destination_cidr_block = "0.0.0.0/0"
}

data "aws_route_table" "network_firewall_route_table" {
  for_each = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network-dr", false) ? {
    for k, v in data.terraform_remote_state.network-firewall-dr.outputs["network_firewall_subnets-dr"] :
  k => v } : {}

  subnet_id = each.value
}

resource "aws_route" "network_firewall_tgw" {
  for_each = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network-dr", false) ? {
    for s in data.terraform_remote_state.network-firewall-dr.outputs["sync_states"][0] :
    s["availability_zone"] => s["attachment"]
  } : {}

  route_table_id         = data.aws_route_table.network_firewall_route_table[each.key].id
  transit_gateway_id     = module.tgw-dr[0].transit_gateway_id
  destination_cidr_block = "0.0.0.0/0"
}
