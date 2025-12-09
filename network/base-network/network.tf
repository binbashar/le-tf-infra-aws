#===========================================#
# VPC Module
# Maps vpc_config design spec to terraform-aws-modules/vpc/aws module
# All computed values (locals) are defined in runtime.tf
#===========================================#
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  # version = var.vpc_config.version # Variables not allowed in module version

  # 1. VPC Core Configuration
  name                 = var.vpc_config.vpc.metadata.name
  cidr                 = var.vpc_config.vpc.networking.cidrBlock
  azs                  = local.all_azs
  enable_dns_hostnames = var.vpc_config.vpc.networking.dnsSettings.enableDnsHostnames
  enable_dns_support   = var.vpc_config.vpc.networking.dnsSettings.enableDnsSupport
  tags                 = var.vpc_config.vpc.metadata.tags

  # 2. Subnets Configuration
  # Public subnets
  public_subnets            = local.public_subnets_cidrs
  public_subnet_names       = local.public_subnet_names
  public_subnet_tags_per_az = length(local.public_subnet_tags_per_az) > 0 ? local.public_subnet_tags_per_az : {}
  map_public_ip_on_launch   = try(var.vpc_config.vpc.networking.mapPublicIpOnLaunch, false)

  # Private subnets
  private_subnets            = local.private_subnets_cidrs
  private_subnet_names       = local.private_subnet_names
  private_subnet_tags_per_az = length(local.private_subnet_tags_per_az) > 0 ? local.private_subnet_tags_per_az : {}

  # Database subnets
  database_subnets             = local.database_subnets_cidrs
  database_subnet_names        = local.database_subnet_names
  create_database_subnet_group = length(local.database_subnets_cidrs) > 0
  database_subnet_tags         = length(local.database_subnet_tags) > 0 ? local.database_subnet_tags : {}

  # Redshift subnets
  redshift_subnets             = local.redshift_subnets_cidrs
  redshift_subnet_names        = local.redshift_subnet_names
  create_redshift_subnet_group = length(local.redshift_subnets_cidrs) > 0
  redshift_subnet_tags         = length(local.redshift_subnet_tags) > 0 ? local.redshift_subnet_tags : {}

  # Elasticache subnets
  elasticache_subnets             = local.elasticache_subnets_cidrs
  elasticache_subnet_names        = local.elasticache_subnet_names
  create_elasticache_subnet_group = length(local.elasticache_subnets_cidrs) > 0
  elasticache_subnet_tags         = length(local.elasticache_subnet_tags) > 0 ? local.elasticache_subnet_tags : {}

  # Intra subnets (no internet access)
  intra_subnets      = local.intra_subnets_cidrs
  intra_subnet_names = local.intra_subnet_names
  intra_subnet_tags  = length(local.intra_subnet_tags) > 0 ? local.intra_subnet_tags : {}

  # Outpost subnets (for AWS Outposts)
  outpost_subnets      = local.outpost_subnets_cidrs
  outpost_subnet_names = local.outpost_subnet_names
  outpost_subnet_tags  = length(local.outpost_subnet_tags) > 0 ? local.outpost_subnet_tags : {}

  # 3. Internet Gateway
  create_igw = var.vpc_config.vpc.networking.internetGateway.enabled

  # 4. NAT Gateway Configuration
  enable_nat_gateway     = local.enable_nat_gateway
  single_nat_gateway     = local.single_nat_gateway
  one_nat_gateway_per_az = local.one_nat_gateway_per_az
  reuse_nat_ips          = length(local.external_nat_ip_ids) > 0
  external_nat_ip_ids    = local.external_nat_ip_ids

  # 5. VPC Flow Logs
  enable_flow_log           = local.flow_logs_enabled
  flow_log_traffic_type     = var.vpc_config.vpc.monitoring.flowLogs.trafficType
  flow_log_destination_type = local.flow_log_destination_type

  # CloudWatch Flow Logs
  create_flow_log_cloudwatch_log_group            = local.flow_logs_enabled && local.flow_log_destination_type == "cloud-watch-logs"
  create_flow_log_cloudwatch_iam_role             = local.flow_logs_enabled && local.flow_log_destination_type == "cloud-watch-logs"
  flow_log_cloudwatch_log_group_name_prefix       = local.flow_logs_enabled && local.flow_log_destination_type == "cloud-watch-logs" ? "/aws/vpc-flow-log/" : null
  flow_log_cloudwatch_log_group_retention_in_days = local.flow_logs_enabled ? var.vpc_config.vpc.monitoring.flowLogs.retentionDays : null

  # 6. Default Resources Management
  # Default VPC
  manage_default_vpc               = try(var.vpc_config.vpc.defaultResources.manageDefaultVpc, false)
  default_vpc_name                 = try(var.vpc_config.vpc.defaultResources.defaultVpcName, null)
  default_vpc_enable_dns_support   = try(var.vpc_config.vpc.defaultResources.defaultVpcEnableDnsSupport, true)
  default_vpc_enable_dns_hostnames = try(var.vpc_config.vpc.defaultResources.defaultVpcEnableDnsHostnames, true)
  default_vpc_tags                 = try(var.vpc_config.vpc.defaultResources.defaultVpcTags, {})

  # Default Security Group
  manage_default_security_group  = try(var.vpc_config.vpc.defaultResources.manageDefaultSecurityGroup, true)
  default_security_group_name    = try(var.vpc_config.vpc.defaultResources.defaultSecurityGroupName, null)
  default_security_group_ingress = try(var.vpc_config.vpc.defaultResources.defaultSecurityGroupIngress, [])
  default_security_group_egress  = try(var.vpc_config.vpc.defaultResources.defaultSecurityGroupEgress, [])
  default_security_group_tags    = try(var.vpc_config.vpc.defaultResources.defaultSecurityGroupTags, {})

  # Default Network ACL
  manage_default_network_acl  = try(var.vpc_config.vpc.defaultResources.manageDefaultNetworkAcl, true)
  default_network_acl_name    = try(var.vpc_config.vpc.defaultResources.defaultNetworkAclName, null)
  default_network_acl_ingress = try(var.vpc_config.vpc.defaultResources.defaultNetworkAclIngress, [])
  default_network_acl_egress  = try(var.vpc_config.vpc.defaultResources.defaultNetworkAclEgress, [])
  default_network_acl_tags    = try(var.vpc_config.vpc.defaultResources.defaultNetworkAclTags, {})

  # Default Route Table
  manage_default_route_table           = try(var.vpc_config.vpc.defaultResources.manageDefaultRouteTable, true)
  default_route_table_name             = try(var.vpc_config.vpc.defaultResources.defaultRouteTableName, null)
  default_route_table_propagating_vgws = try(var.vpc_config.vpc.defaultResources.defaultRouteTablePropagatingVgws, [])
  default_route_table_routes           = try(var.vpc_config.vpc.defaultResources.defaultRouteTableRoutes, [])
  default_route_table_tags             = try(var.vpc_config.vpc.defaultResources.defaultRouteTableTags, {})
}
