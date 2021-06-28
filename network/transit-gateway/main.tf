module "tgw" {

  source = "github.com/binbashar/terraform-aws-transit-gateway-1?ref=0.4.0"

  enabled = var.enabled_tgw
  name    = "${var.project}-tgw"

  ram_resource_share_enabled = true

  create_transit_gateway                                         = true
  create_transit_gateway_route_table                             = true
  create_transit_gateway_vpc_attachment                          = false
  create_transit_gateway_route_table_association_and_propagation = true

  config = merge(
    # network private
    lookup(var.enabled_vpc_attach, "apps-network", false) ? {
      for k, v in data.terraform_remote_state.network-vpcs : v.outputs.vpc_id => {
        vpc_id                            = null
        vpc_cidr                          = null
        subnet_ids                        = null
        subnet_route_table_ids            = null
        route_to                          = null
        route_to_cidr_blocks              = null
        transit_gateway_vpc_attachment_id = module.tgw_vpc_attachments_and_subnet_routes_network[0].transit_gateway_vpc_attachment_ids[k]
        static_routes                     = []
      }
    } : {},
    # apps-devstg private
    lookup(var.enabled_vpc_attach, "apps-devstg", false) ? {
      for k, v in data.terraform_remote_state.apps-devstg-vpcs : v.outputs.vpc_id => {
        vpc_id                            = null
        vpc_cidr                          = null
        subnet_ids                        = null
        subnet_route_table_ids            = null
        route_to                          = null
        route_to_cidr_blocks              = null
        transit_gateway_vpc_attachment_id = module.tgw_vpc_attachments_and_subnet_routes_apps-devstg[0].transit_gateway_vpc_attachment_ids[k]
        static_routes                     = []
      }
    } : {},
    # apps-prd private
    lookup(var.enabled_vpc_attach, "apps-prd", false) ? {
      for k, v in data.terraform_remote_state.apps-prd-vpcs : v.outputs.vpc_id => {
        vpc_id                            = null
        vpc_cidr                          = null
        subnet_ids                        = null
        subnet_route_table_ids            = null
        route_to                          = null
        route_to_cidr_blocks              = null
        transit_gateway_vpc_attachment_id = module.tgw_vpc_attachments_and_subnet_routes_apps-prd[0].transit_gateway_vpc_attachment_ids[k]
        static_routes                     = []
      }
    } : {},
  )

  providers = {
    aws = aws.network
  }
}
