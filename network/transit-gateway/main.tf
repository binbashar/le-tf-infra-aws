#
# Transit Gateway
#
module "tgw" {
  source = "github.com/binbashar/terraform-aws-transit-gateway.git?ref=v2.4.0"

  # Enable TGW
  create_tgw = var.enable_tgw

  name                                   = "${var.project_long}-tgw"
  description                            = "TGW shared with several other AWS accounts"
  enable_auto_accept_shared_attachments  = lookup(var.tgw_defaults, "enable_auto_accept_shared_attachments", true) # When "true" there is no need for RAM resources if using multiple AWS accounts
  enable_default_route_table_association = lookup(var.tgw_defaults, "enable_default_route_table_association", true)
  enable_default_route_table_propagation = lookup(var.tgw_defaults, "enable_default_route_table_propagation", true)
  enable_dns_support                     = lookup(var.tgw_defaults, "enable_dns_support", true)
  enable_vpn_ecmp_support                = lookup(var.tgw_defaults, "enable_vpn_ecmp_support", true)
  ram_allow_external_principals          = lookup(var.tgw_defaults, "ram_allow_external_principals", false)
  ram_principals                         = var.ram_principals
  share_tgw                              = lookup(var.tgw_defaults, "share_tgw", true)


  vpc_attachments = {
    for vpc in data.terraform_remote_state.vpcs : vpc.outputs.vpc_id => {
      vpc_id                                          = vpc.outputs.vpc_id          # module.vpc.vpc_id
      subnet_ids                                      = vpc.outputs.private_subnets # module.vpc.private_subnets
      dns_support                                     = lookup(var.tgw_defaults["vpc_attachments"], "dns_support", true)
      ipv6_support                                    = lookup(var.tgw_defaults["vpc_attachments"], "ipv6_support", false)
      transit_gateway_default_route_table_association = lookup(var.tgw_defaults["vpc_attachments"], "transit_gateway_default_route_table_association", false)
      transit_gateway_default_route_table_propagation = lookup(var.tgw_defaults["vpc_attachments"], "transit_gateway_default_route_table_propagation", false)

      tgw_routes = [
        {
          destination_cidr_block = "30.0.0.0/16"
        },
        {
          blackhole              = true
          destination_cidr_block = "0.0.0.0/0"
        }
      ]
    }
  }

  tags = local.tags
}
