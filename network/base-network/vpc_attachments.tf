# network VPC attachments (private)
module "tgw_vpc_attachments_and_subnet_routes_network" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  count = var.enabled_tgw && var.enabled_vpc_attach["network"] ? 1 : 0

  # network account can access the Transit Gateway in the network: account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = module.tgw[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    for k, v in data.terraform_remote_state.network-vpcs : k => {
      vpc_id                            = v.outputs.vpc_id
      vpc_cidr                          = v.outputs.vpc_cidr_block
      subnet_ids                        = v.outputs.private_subnets
      subnet_route_table_ids            = v.outputs.private_route_table_ids
      route_to                          = null
      route_to_cidr_blocks              = null
      static_routes                     = null
      transit_gateway_vpc_attachment_id = null
    }
  }

  tags = {
    Name = "${var.project}-network-vpc-attach"
  }

  providers = {
    aws = aws.network
  }
}

# apps-devstg VPC attachments
module "tgw_vpc_attachments_and_subnet_routes_apps-devstg" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  count = var.enabled_tgw && var.enabled_vpc_attach["apps-devstg"] ? 1 : 0

  # apps-devstg account can access the Transit Gateway in the network account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = module.tgw[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    for k, v in data.terraform_remote_state.apps-devstg-vpcs : k => {
      vpc_id                 = v.outputs.vpc_id
      vpc_cidr               = v.outputs.vpc_cidr_block
      subnet_ids             = v.outputs.private_subnets
      subnet_route_table_ids = v.outputs.private_route_table_ids
      route_to               = null
      route_to_cidr_blocks = concat(
        ["0.0.0.0/0"], #tgw
        #[for v in values(data.terraform_remote_state.shared-vpcs) : v.outputs.vpc_cidr_block],  # shared
        #[for v in values(data.terraform_remote_state.network-vpcs) : v.outputs.vpc_cidr_block], # network
      )

      static_routes                     = null
      transit_gateway_vpc_attachment_id = null
    }
  }

  tags = {
    Name = "${var.project}-apps-devstg-vpc-attach"
  }

  providers = {
    aws = aws.apps-devstg
  }
}

# apps-prd VPC attachments
module "tgw_vpc_attachments_and_subnet_routes_apps-prd" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  count = var.enabled_tgw && var.enabled_vpc_attach["apps-prd"] ? 1 : 0

  name = "${var.project}-apps-prd-vpc-attach"

  # apps-prd account can access the Transit Gateway in the network account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = module.tgw[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    for k, v in data.terraform_remote_state.apps-prd-vpcs : k => {
      vpc_id                 = v.outputs.vpc_id
      vpc_cidr               = v.outputs.vpc_cidr_block
      subnet_ids             = v.outputs.private_subnets
      subnet_route_table_ids = v.outputs.private_route_table_ids
      route_to               = null
      route_to_cidr_blocks = concat(
        ["0.0.0.0/0"], #tgw
        #[for v in values(data.terraform_remote_state.shared-vpcs) : v.outputs.vpc_cidr_block], # shared
        #[for v in values(data.terraform_remote_state.network-vpcs) : v.outputs.vpc_cidr_block], # network
      )
      static_routes                     = null
      transit_gateway_vpc_attachment_id = null
    }
  }

  tags = {
    Name = "${var.project}-apps-prd-vpc-attach"
  }

  providers = {
    aws = aws.apps-prd
  }
}
