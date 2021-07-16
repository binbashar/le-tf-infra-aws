# network inspection VPC attachments (private)
module "tgw_vpc_attachments_and_subnet_routes_network_inspection" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  for_each = {
    for k, v in { "network-inspection" = data.terraform_remote_state.network-vpcs["network-inspection"] } :
    k => v if var.enable_tgw && var.enable_network_firewall
  }

  # network account can access the Transit Gateway in the network: account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = true
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    (each.key) = {
      vpc_id                 = each.value.outputs.vpc_id
      vpc_cidr               = each.value.outputs.vpc_cidr_block
      subnet_ids             = each.value.outputs.private_subnets
      subnet_route_table_ids = each.value.outputs.private_route_table_ids
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
    Name = "${var.project}-${each.key}-vpc-attach"
  }

  providers = {
    aws = aws.network
  }
}

# network VPC attachments (private)
module "tgw_vpc_attachments_and_subnet_routes_network" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  for_each = {
    for k, v in { "network-base" = data.terraform_remote_state.network-vpcs["network-base"] } :
    k => v if var.enable_tgw && var.enable_network_firewall && lookup(var.enable_vpc_attach, "network", false)
  }

  # network account can access the Transit Gateway in the network: account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = module.tgw[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false

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

  tags = {
    Name = "${var.project}-${each.key}-vpc"
  }

  providers = {
    aws = aws.network
  }
}

# apps-devstg VPC attachments
module "tgw_vpc_attachments_and_subnet_routes_apps-devstg" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  for_each = {
    for k, v in data.terraform_remote_state.apps-devstg-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg", false)
  }

  # apps-devstg account can access the Transit Gateway in the network account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = var.enable_tgw && lookup(var.enable_vpc_attach, "apps-devstg", false) ? module.tgw_vpc_attachments_and_subnet_routes_network_inspection["network-inspection"].transit_gateway_route_table_id : module.tgw[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    (each.key) = {
      vpc_id                 = each.value.outputs.vpc_id
      vpc_cidr               = each.value.outputs.vpc_cidr_block
      subnet_ids             = each.value.outputs.private_subnets
      subnet_route_table_ids = each.value.outputs.private_route_table_ids
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
    Name = "${var.project}-apps-devstg-vpc"
  }

  providers = {
    aws = aws.apps-devstg
  }
}

# apps-prd VPC attachments
module "tgw_vpc_attachments_and_subnet_routes_apps-prd" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  for_each = {
    for k, v in data.terraform_remote_state.apps-prd-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd", false)
  }

  name = "${var.project}-apps-prd-vpc-attach"

  # apps-prd account can access the Transit Gateway in the network account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = var.enable_tgw && lookup(var.enable_vpc_attach, "apps-prd", false) ? module.tgw_vpc_attachments_and_subnet_routes_network_inspection["network-inspection"].transit_gateway_route_table_id : module.tgw[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    (each.key) = {
      vpc_id                 = each.value.outputs.vpc_id
      vpc_cidr               = each.value.outputs.vpc_cidr_block
      subnet_ids             = each.value.outputs.private_subnets
      subnet_route_table_ids = each.value.outputs.private_route_table_ids
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
    Name = "${var.project}-apps-prd-vpc"
  }

  providers = {
    aws = aws.apps-prd
  }
}

# shared VPC attachments
module "tgw_vpc_attachments_and_subnet_routes_shared" {

  source = "github.com/binbashar/terraform-aws-transit-gateway?ref=0.4.0"

  for_each = {
    for k, v in data.terraform_remote_state.shared-vpcs :
    k => v if var.enable_tgw && lookup(var.enable_vpc_attach, "shared", false)
  }

  # apps-devstg account can access the Transit Gateway in the network account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id                                    = module.tgw[0].transit_gateway_id
  existing_transit_gateway_route_table_id                        = var.enable_tgw && lookup(var.enable_vpc_attach, "shared", false) ? module.tgw_vpc_attachments_and_subnet_routes_network_inspection["network-inspection"].transit_gateway_route_table_id : module.tgw[0].transit_gateway_route_table_id
  create_transit_gateway                                         = false
  create_transit_gateway_route_table                             = false
  create_transit_gateway_vpc_attachment                          = true
  create_transit_gateway_route_table_association_and_propagation = false

  config = {
    (each.key) = {
      vpc_id                 = each.value.outputs.vpc_id
      vpc_cidr               = each.value.outputs.vpc_cidr_block
      subnet_ids             = each.value.outputs.private_subnets
      subnet_route_table_ids = each.value.outputs.private_route_table_ids
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
    Name = "${var.project}-shared-vpc"
  }

  providers = {
    aws = aws.shared
  }
}
