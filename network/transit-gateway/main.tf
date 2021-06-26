module "transit_gateway" {
  source  = "cloudposse/transit-gateway/aws"
  version = "0.4.0"

  name = "${var.project_long}-tgw"

  ram_resource_share_enabled = true

  create_transit_gateway                                         = true
  create_transit_gateway_route_table                             = true
  create_transit_gateway_vpc_attachment                          = false
  create_transit_gateway_route_table_association_and_propagation = true

  config = {
    for k, v in data.terraform_remote_state.apps-prd-vpcs : v.outputs.vpc_id => {
      vpc_id                            = null
      vpc_cidr                          = null
      subnet_ids                        = null
      subnet_route_table_ids            = null
      route_to                          = null
      route_to_cidr_blocks              = null
      transit_gateway_vpc_attachment_id = module.transit_gateway_vpc_attachments_and_subnet_routes_prod.transit_gateway_vpc_attachment_ids[k]
      static_routes = [
        {
          blackhole              = true
          destination_cidr_block = "0.0.0.0/0"
        },
        {
          blackhole              = false
          destination_cidr_block = "172.16.1.0/24"
        }
      ]
    }
  }

}

module "transit_gateway_vpc_attachments_and_subnet_routes_prod" {

  source  = "cloudposse/transit-gateway/aws"
  version = "0.4.0"

  #for_each = data.terraform_remote_state.apps-prd-vpcs

  # `prod` account can access the Transit Gateway in the `network` account since we shared the Transit Gateway with the Organization using Resource Access Manager
  existing_transit_gateway_id             = module.transit_gateway.transit_gateway_id
  existing_transit_gateway_route_table_id = module.transit_gateway.transit_gateway_route_table_id

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
        [
          #"172.18.32.0/20", # apps-devstg
          #"172.19.0.0/20",  # apps-devstg/k8s-eks
          #"172.19.16.0/20"  # apps-devstg/k8s-eks-demoapps
        ],
        #[for v in values(data.terraform_remote_state.shared-vpcs) : v.outputs.vpc_cidr_block],      # shared
        [for v in values(data.terraform_remote_state.network-vpcs) : v.outputs.vpc_cidr_block],     # network
        [for v in values(data.terraform_remote_state.apps-devstg-vpcs) : v.outputs.vpc_cidr_block], # apps-devstg
      )

      static_routes                     = null
      transit_gateway_vpc_attachment_id = null
    }
  }

  providers = {
    aws = aws.apps-prd
  }
}
