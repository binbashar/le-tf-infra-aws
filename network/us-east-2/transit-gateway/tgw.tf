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
    # network private
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
    # apps-devstg private
    lookup(var.enable_vpc_attach, "apps-devstg-dr", false) ? {
      for k, v in data.terraform_remote_state.apps-devstg-dr-vpcs : v.outputs.vpc_id => {
        vpc_id                            = null
        vpc_cidr                          = null
        subnet_ids                        = null
        subnet_route_table_ids            = null
        route_to                          = null
        route_to_cidr_blocks              = null
        transit_gateway_vpc_attachment_id = module.tgw_vpc_attachments_and_subnet_routes_apps-devstg-dr[k].transit_gateway_vpc_attachment_ids[k]
        static_routes                     = null
      }
    } : {},
    # apps-prd private
    lookup(var.enable_vpc_attach, "apps-prd-dr", false) ? {
      for k, v in data.terraform_remote_state.apps-prd-dr-vpcs : v.outputs.vpc_id => {
        vpc_id                            = null
        vpc_cidr                          = null
        subnet_ids                        = null
        subnet_route_table_ids            = null
        route_to                          = null
        route_to_cidr_blocks              = null
        transit_gateway_vpc_attachment_id = module.tgw_vpc_attachments_and_subnet_routes_apps-prd-dr[k].transit_gateway_vpc_attachment_ids[k]
        static_routes                     = null
      }
    } : {},
    # shared private
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
# Route Table defitions
#
module "tgw_inspection_route_table" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? 1 : 0

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

#
# Network Firewall
#
resource "aws_ec2_transit_gateway_route" "inspection_default" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network-firewall-dr["network-firewall-dr"].transit_gateway_vpc_attachment_ids["network-firewall-dr"]
}

resource "aws_ec2_transit_gateway_route" "network_firewall_default" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network-dr["network-base"].transit_gateway_vpc_attachment_ids["network-base"]
}

resource "aws_ec2_transit_gateway_route_table_association" "network-inspection-association" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? 1 : 0

  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network-firewall-dr["network-firewall-dr"].transit_gateway_vpc_attachment_ids["network-firewall-dr"]
}

resource "aws_ec2_transit_gateway_route_table_association" "network-base-association" {
  count = var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false) ? 1 : 0

  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_network-dr["network-base-dr"].transit_gateway_vpc_attachment_ids["network-base-dr"]
}

# shared
resource "aws_ec2_transit_gateway_route_table_association" "shared-rt-associations" {

  for_each = {
    for k, v in data.terraform_remote_state.shared-dr-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "shared", false)
  }

  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_shared-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared-rt-propagations" {
  for_each = {
    for k, v in data.terraform_remote_state.shared-dr-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "shared", false)
  }

  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_shared-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]

}

# apps-devstg
resource "aws_ec2_transit_gateway_route_table_association" "apps-devstg-rt-associations" {

  for_each = {
    for k, v in data.terraform_remote_state.apps-devstg-dr-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "apps-devstg", false)
  }

  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-devstg-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "apps-devstg-rt-propagations" {
  for_each = {
    for k, v in data.terraform_remote_state.apps-devstg-dr-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "apps-devstg", false)
  }

  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-devstg-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]

}

# apps-prd
resource "aws_ec2_transit_gateway_route_table_association" "apps-prd-rt-associations" {

  for_each = {
    for k, v in data.terraform_remote_state.apps-prd-dr-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "apps-prd-dr", false)
  }

  transit_gateway_route_table_id = module.tgw_inspection_route_table[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-prd-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "apps-prd-rt-propagations" {
  for_each = {
    for k, v in data.terraform_remote_state.apps-prd-dr-vpcs :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "apps-prd-dr", false)
  }

  transit_gateway_route_table_id = module.tgw-dr[0].transit_gateway_route_table_id
  transit_gateway_attachment_id  = module.tgw_vpc_attachments_and_subnet_routes_apps-prd-dr[each.key].transit_gateway_vpc_attachment_ids[each.key]

}

#
# Update network public RT
#
resource "aws_route" "apps_devstg_public_route_to_tgw" {

  # For each vpc...
  for_each = {
    for k, v in data.terraform_remote_state.apps-devstg-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg-dr", false)
  }

  # ...add a route into the network public RT
  route_table_id         = data.terraform_remote_state.network-dr-vpcs["network-base-dr"].outputs.public_route_table_ids[0]
  destination_cidr_block = each.value.outputs.vpc_cidr_block
  transit_gateway_id     = module.tgw-dr[0].transit_gateway_id

  depends_on = [module.tgw-dr, module.tgw_vpc_attachments_and_subnet_routes_network-dr]

}

resource "aws_route" "apps_prd_public_route_to_tgw" {

  # For each vpc...
  for_each = {
    for k, v in data.terraform_remote_state.apps-prd-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd-dr", false)
  }

  # ...add a route into the network public RT
  route_table_id         = data.terraform_remote_state.network-dr-vpcs["network-base-dr"].outputs.public_route_table_ids[0]
  destination_cidr_block = each.value.outputs.vpc_cidr_block
  transit_gateway_id     = module.tgw-dr[0].transit_gateway_id

  depends_on = [module.tgw-dr, module.tgw_vpc_attachments_and_subnet_routes_network-dr]

}

# Update shared public RT
resource "aws_route" "shared_public_apps_devstg_route_to_tgw" {

  # For each vpc...
  for_each = {
    for k, v in data.terraform_remote_state.apps-devstg-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg-dr", false)
  }

  # ...add a route into the network public RT
  route_table_id         = data.terraform_remote_state.shared-dr-vpcs["shared-base-dr"].outputs.public_route_table_ids[0]
  destination_cidr_block = each.value.outputs.vpc_cidr_block
  transit_gateway_id     = module.tgw-dr[0].transit_gateway_id

  depends_on = [module.tgw-dr, module.tgw_vpc_attachments_and_subnet_routes_network-dr]

  provider = aws.shared

}

resource "aws_route" "shared_public_apps_prd_route_to_tgw" {

  # For each vpc...
  for_each = {
    for k, v in data.terraform_remote_state.apps-prd-dr-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd-dr", false)
  }

  # ...add a route into the network public RT
  route_table_id         = data.terraform_remote_state.shared-dr-vpcs["shared-base-dr"].outputs.public_route_table_ids[0]
  destination_cidr_block = each.value.outputs.vpc_cidr_block
  transit_gateway_id     = module.tgw-dr[0].transit_gateway_id

  depends_on = [module.tgw-dr, module.tgw_vpc_attachments_and_subnet_routes_network-dr]

  provider = aws.shared

}

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
