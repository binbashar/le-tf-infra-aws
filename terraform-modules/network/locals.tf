locals {

  # #######################################
  # VPC DATA
  #

  vpc_name = "${var.project}-${var.environment}-vpc-${var.vpc_name_suffix}"

  # max expected number of AZs is 3!
  max_allowed_azs = 4

  num = (pow(2,var.subnet_bits) / local.max_allowed_azs)
  network_num = [for i in range(0, pow(2,var.subnet_bits), local.num): i]

  azs_internal = [ for az in var.availability_zones: "${var.region}${az}" ]

  private_cidr = cidrsubnet(var.vpc_cidr, 1, 0)
  public_cidr  = cidrsubnet(var.vpc_cidr, 1, 1)

  private_vpc_subnets = var.create_public_subnet == false ? [] : flatten([
      for i in range(length(var.availability_zones)) : {
        name        = "${var.project}-${i}"
        vpc_name    = var.project
        cidr_block  = local.private_cidr
        subnet_bits = var.subnet_bits
        network_num = local.network_num[i]
      }
  ])
  private_subnet_cidrs = [ for s in local.private_vpc_subnets : cidrsubnet(s.cidr_block, s.subnet_bits, s.network_num) ]

  public_vpc_subnets = var.create_private_subnet == false ? [] : flatten([
      for i in range(length(var.availability_zones)) : {
        name        = "${var.project}-${i}"
        vpc_name    = var.project
        cidr_block  = local.public_cidr
        subnet_bits = var.subnet_bits
        network_num = local.network_num[i]
      }
  ])
  public_subnet_cidrs = [ for s in local.public_vpc_subnets : cidrsubnet(s.cidr_block, s.subnet_bits, s.network_num) ]


  # #######################################
  # NETWORK ACL DATA
  #


  # first we concatenate the base elements
  #
  # PRIVATE INBOUND RULES
  # Basically accept traffic from shared base vpc and additional ones if supplied
  #datasources_vpc is
  # {
  # "vpcname" => [
  #   "172.18.0.0/21",
  #  ]
  #  }
  #
  # Here default shared base vpc is defined, unless var.shared_vpcs ovewrites it
  # This default is set following the binbash Leverage conventions
  shared_vpcs_default = var.shared_vpcs == null && var.create_acl_for_shared_vpcs ? {
    shared-base = {
      region  = var.shared-base-terraform-background-region == null ? var.region : var.shared-base-terraform-background-region
      profile = "${var.project}-shared-devops"
      bucket  = "${var.project}-shared-terraform-backend"
      key     = var.shared-base-terraform-background-key
    }
  } : {}
  # if shared-vpcx-default is used then we need to create the remote state
  shared_vpcs_default_remote_state_1 = var.accept_traffic_from_private_shared ? { for k,vpc in data.terraform_remote_state.shared-vpcs: "${k}-pri" => vpc.outputs.private_subnets_cidr } : {}
  shared_vpcs_default_remote_state = var.accept_traffic_from_public_shared ? merge(local.shared_vpcs_default_remote_state_1, { for k,vpc in data.terraform_remote_state.shared-vpcs: "${k}-pub" => vpc.outputs.public_subnets_cidr }) : local.shared_vpcs_default_remote_state_1
  # set the shared vpc local or ovewriten by param
  shared_vpcs = var.shared_vpcs != null ? var.shared_vpcs : local.shared_vpcs_default_remote_state
  # allow income traffic from shared vpcs
  private_inbound_1 = flatten([
    for index, state in local.shared_vpcs : [
      for k, v in state :
      {
        rule_number = 10 * (index(keys(local.shared_vpcs), index) + 1) + 100 * k
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = state[k]
      }
    ]
  ])

  # ADDITIONAL ACL Rules
  private_inbound_2 = [
    local.private_inbound_1,
    var.additional_private_acl_rules != null ? var.additional_private_acl_rules : null
  ]
  # flatten the files
  private_inbound_3 = flatten([for rule in local.private_inbound_2 : rule if rule != null])

  # DEFAULT INBOUND RULES
  default_inbound_1 = [
    {
      rule_number = 200 # Allow traffic from this vpc's private subnets
      rule_action = "allow"
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      cidr_block  = local.private_cidr
    },
    {
      rule_number = 910 # NTP traffic
      rule_action = "allow"
      from_port   = 123
      to_port     = 123
      protocol    = "udp"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number = 920 # Fltering known TCP ports (0-1024)
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65525
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number = 930 # Fltering known UDP ports (0-1024)
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65525
      protocol    = "udp"
      cidr_block  = "0.0.0.0/0"
    },
  ]
  # get the VPN Server Private IP
  vpn_private_ip = var.vpn_private_ip == null && var.create_acl_for_vpn_ip ? data.terraform_remote_state.tools-vpn-server[0].outputs.instance_private_ip : var.vpn_private_ip != null && var.create_acl_for_vpn_ip ? var.vpn_private_ip : null
  # VPN ACL Rule
  default_inbound_2 = [{
        rule_number = 900 # shared pritunl vpn server
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = "${var.vpn_private_ip != null ? var.vpn_private_ip : ""}/32"
  }]
  # concatenate 1 and 2
  default_inbound_3 = [
    local.default_inbound_1,
    var.vpn_private_ip != null ? local.default_inbound_2 : null
  ]
  # ADDITIONAL ACL Rules
  default_inbound_4 = [
    local.default_inbound_1,
    var.additional_acl_rules != null ? var.additional_acl_rules : null
  ]
  # faltten them all
  default_inbound_5 = flatten([for rule in local.default_inbound_4 : rule if rule != null])


  # finally we create the meged element
  network_acls = {
    #
    # Allow / Deny VPC private subnets inbound default traffic
    #
    default_inbound = local.default_inbound_5
    #
    # Allow VPC private subnets inbound traffic
    #
    private_inbound = local.private_inbound_3
  }

  # #######################################
  # TAGS

  tags_1 = {
    Terraform   = "true"
    Project     = var.project
    Environment = var.environment
  }
  tags = merge(var.tags, local.tags_1)

  public_subnet_tags_1 = {}
  public_subnet_tags = merge(var.public_subnet_tags, local.public_subnet_tags_1)
  private_subnet_tags_1 = {}
  private_subnet_tags = merge(var.private_subnet_tags, local.private_subnet_tags_1)


  # #######################################
  # VPC ENDPOINTS
  vpc_endpoints = var.enable_s3_dynamodb_vpce ? merge({
    # S3
    s3 = {
      service      = "s3"
      service_type = "Gateway"
    }
    # DynamamoDB
    dynamodb = {
      service      = "dynamodb"
      service_type = "Gateway"
    }
  }) : {}


  # #######################################
  # VPC PEERINGS TO SHARED
  shared_vpcs_peerings = var.create_vpc_peerings_for_shared_vpcs ? local.shared_vpcs_default : {}
}
