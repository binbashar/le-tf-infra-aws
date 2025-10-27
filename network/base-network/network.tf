module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"
  
  # 1. VPC Core Configuration
  name                = var.vpc_config.name
  cidr                = var.vpc_config.cidr
  secondary_cidr_blocks = var.vpc_config.secondary_cidrs
  azs                 = var.vpc_config.azs
  instance_tenancy    = var.vpc_config.instance_tenancy
  enable_dns_hostnames = var.vpc_config.enable_dns_hostnames
  enable_dns_support  = var.vpc_config.enable_dns_support
  enable_ipv6         = var.vpc_config.enable_ipv6
  ipv6_cidr           = var.vpc_config.ipv6_cidr
  tags                = var.vpc_config.tags
  
  # 2. Subnets Configuration
  # Public subnets
  public_subnets              = var.subnets_config.public.cidrs
  public_subnet_ipv6_prefixes = var.subnets_config.public.ipv6_prefixes
  map_public_ip_on_launch     = var.subnets_config.public.map_public_ip
  public_subnet_names         = var.subnets_config.public.names
  public_subnet_tags          = var.subnets_config.public.tags
  public_subnet_tags_per_az   = var.subnets_config.public.tags_per_az
  
  # Private subnets
  private_subnets                 = var.subnets_config.private.cidrs
  private_subnet_ipv6_prefixes    = var.subnets_config.private.ipv6_prefixes
  private_subnet_names            = var.subnets_config.private.names
  create_private_nat_gateway_route = var.subnets_config.private.create_nat_gateway_route
  private_subnet_tags             = var.subnets_config.private.tags
  private_subnet_tags_per_az      = var.subnets_config.private.tags_per_az
  
  # Database subnets
  database_subnets                    = var.subnets_config.database.cidrs
  create_database_subnet_group        = var.subnets_config.database.create_subnet_group
  database_subnet_group_name          = var.subnets_config.database.subnet_group_name
  create_database_nat_gateway_route   = var.subnets_config.database.create_nat_gateway_route
  create_database_internet_gateway_route = var.subnets_config.database.create_internet_gateway_route
  database_subnet_tags                = var.subnets_config.database.tags
  
  # Elasticache subnets
  elasticache_subnets           = var.subnets_config.elasticache.cidrs
  create_elasticache_subnet_group = var.subnets_config.elasticache.create_subnet_group
  elasticache_subnet_group_name = var.subnets_config.elasticache.subnet_group_name
  elasticache_subnet_tags       = var.subnets_config.elasticache.tags
  
  # Redshift subnets
  redshift_subnets              = var.subnets_config.redshift.cidrs
  create_redshift_subnet_group  = var.subnets_config.redshift.create_subnet_group
  redshift_subnet_group_name    = var.subnets_config.redshift.subnet_group_name
  enable_public_redshift        = var.subnets_config.redshift.enable_public
  redshift_subnet_tags          = var.subnets_config.redshift.tags
  
  # Intra subnets
  intra_subnets     = var.subnets_config.intra.cidrs
  intra_subnet_tags = var.subnets_config.intra.tags
  
  # 3. Network ACLs Configuration
  manage_default_network_acl     = var.network_acls_config.manage_default
  default_network_acl_ingress    = var.network_acls_config.default_rules.ingress
  default_network_acl_egress     = var.network_acls_config.default_rules.egress
  
  public_dedicated_network_acl   = var.network_acls_config.public.dedicated
  public_inbound_acl_rules       = var.network_acls_config.public.inbound_rules
  public_outbound_acl_rules      = var.network_acls_config.public.outbound_rules
  public_acl_tags                = var.network_acls_config.public.tags
  
  private_dedicated_network_acl  = var.network_acls_config.private.dedicated
  private_inbound_acl_rules      = var.network_acls_config.private.inbound_rules
  private_outbound_acl_rules     = var.network_acls_config.private.outbound_rules
  private_acl_tags               = var.network_acls_config.private.tags
  
  database_dedicated_network_acl = var.network_acls_config.database.dedicated
  database_inbound_acl_rules     = var.network_acls_config.database.inbound_rules
  database_outbound_acl_rules    = var.network_acls_config.database.outbound_rules
  database_acl_tags              = var.network_acls_config.database.tags
  
  # 4. Gateway Configuration
  create_igw             = var.gateway_config.create_igw
  create_egress_only_igw = var.gateway_config.create_egress_only_igw
  
  enable_nat_gateway     = var.gateway_config.enable_nat_gateway
  single_nat_gateway     = var.gateway_config.single_nat_gateway
  one_nat_gateway_per_az = var.gateway_config.one_nat_gateway_per_az
  reuse_nat_ips          = var.gateway_config.reuse_nat_ips
  external_nat_ip_ids    = var.gateway_config.external_nat_ip_ids
  nat_gateway_tags       = var.gateway_config.nat_gateway_tags
  nat_eip_tags           = var.gateway_config.nat_eip_tags
  
  # 5. VPN Configuration
  enable_vpn_gateway             = var.vpn_config.enable_vpn_gateway
  vpn_gateway_id                 = var.vpn_config.vpn_gateway_id
  amazon_side_asn                = var.vpn_config.amazon_side_asn
  vpn_gateway_az                 = var.vpn_config.vpn_gateway_az
  propagate_private_route_tables_vgw = var.vpn_config.propagate_private_route_tables
  propagate_public_route_tables_vgw  = var.vpn_config.propagate_public_route_tables
  propagate_intra_route_tables_vgw   = var.vpn_config.propagate_intra_route_tables
  customer_gateways              = var.vpn_config.customer_gateways
  customer_gateway_tags          = var.vpn_config.customer_gateway_tags
  
  # 6. Default Resources Management
  manage_default_vpc                = var.default_resources_config.manage_default_vpc
  default_vpc_name                  = var.default_resources_config.default_vpc_name
  default_vpc_enable_dns_support    = var.default_resources_config.default_vpc_enable_dns_support
  default_vpc_enable_dns_hostnames  = var.default_resources_config.default_vpc_enable_dns_hostnames
  manage_default_security_group     = var.default_resources_config.manage_default_security_group
  default_security_group_name       = var.default_resources_config.default_security_group_name
  default_security_group_ingress    = var.default_resources_config.default_security_group_ingress
  default_security_group_egress     = var.default_resources_config.default_security_group_egress
  manage_default_route_table        = var.default_resources_config.manage_default_route_table
  default_route_table_routes        = var.default_resources_config.default_route_table_routes
  
  # 7. VPC Flow Logs
  enable_flow_log                  = var.flow_logs_config.enable
  flow_log_traffic_type            = var.flow_logs_config.traffic_type
  flow_log_destination_type        = var.flow_logs_config.destination_type
  flow_log_destination_arn         = var.flow_logs_config.destination_arn
  flow_log_log_format              = var.flow_logs_config.log_format
  flow_log_max_aggregation_interval = var.flow_logs_config.max_aggregation_interval
  
  # CloudWatch
  create_flow_log_cloudwatch_log_group = var.flow_logs_config.cloudwatch.create_log_group
  create_flow_log_cloudwatch_iam_role  = var.flow_logs_config.cloudwatch.create_iam_role
  flow_log_cloudwatch_iam_role_arn     = var.flow_logs_config.cloudwatch.iam_role_arn
  flow_log_cloudwatch_log_group_name_prefix = var.flow_logs_config.cloudwatch.log_group_name_prefix
  flow_log_cloudwatch_log_group_name_suffix = var.flow_logs_config.cloudwatch.log_group_name_suffix
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_logs_config.cloudwatch.retention_in_days
  flow_log_cloudwatch_log_group_kms_key_id = var.flow_logs_config.cloudwatch.kms_key_id
  
  # S3
  flow_log_file_format               = var.flow_logs_config.s3.file_format
  flow_log_hive_compatible_partitions = var.flow_logs_config.s3.hive_compatible_partitions
  flow_log_per_hour_partition        = var.flow_logs_config.s3.per_hour_partition
  
  vpc_flow_log_tags = var.flow_logs_config.tags
  
  # 8. Advanced Features
  enable_dhcp_options              = var.advanced_config.enable_dhcp_options
  dhcp_options_domain_name         = var.advanced_config.dhcp_options.domain_name
  dhcp_options_domain_name_servers = var.advanced_config.dhcp_options.domain_name_servers
  dhcp_options_ntp_servers         = var.advanced_config.dhcp_options.ntp_servers
  dhcp_options_netbios_name_servers = var.advanced_config.dhcp_options.netbios_name_servers
  dhcp_options_netbios_node_type   = var.advanced_config.dhcp_options.netbios_node_type
  
  vpc_block_public_access_options    = var.advanced_config.vpc_block_public_access_options
  vpc_block_public_access_exclusions = var.advanced_config.vpc_block_public_access_exclusions
  enable_network_address_usage_metrics = var.advanced_config.enable_network_address_usage_metrics
}
