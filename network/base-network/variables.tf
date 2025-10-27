#===========================================#
# BASIC CONFIGURATION VARIABLES
#===========================================#
variable "environment" {
  description = "Environment name (devstg, prd, shared)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "profile" {
  description = "AWS profile to use"
  type        = string
  default     = null
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "binbash"
}

variable "layer_name" {
  description = "Layer name for this infrastructure component"
  type        = string
  default     = "base-network"
}

#===========================================#
# VPC Configuration Objects
# Simplified abstraction layer for terraform-aws-modules/vpc/aws
# Groups 1681 variables into 8 logical objects
#===========================================#

#===========================================#
# 1. VPC CORE CONFIGURATION
#===========================================#
variable "vpc_config" {
  description = "VPC core configuration - basic settings for the VPC"
  type = object({
    name                = string
    cidr                = string
    secondary_cidrs     = optional(list(string), [])
    azs                 = list(string)
    instance_tenancy    = optional(string, "default")
    enable_dns_hostnames = optional(bool, true)
    enable_dns_support  = optional(bool, true)
    enable_ipv6         = optional(bool, false)
    ipv6_cidr           = optional(string, null)
    tags                = optional(map(string), {})
  })
}

#===========================================#
# 2. SUBNETS CONFIGURATION
#===========================================#
variable "subnets_config" {
  description = "Subnets configuration for all tiers (public, private, database, etc.)"
  type = object({
    # Public subnets
    public = optional(object({
      cidrs                  = list(string)
      ipv6_prefixes         = optional(list(string), [])
      map_public_ip         = optional(bool, false)
      names                 = optional(list(string), [])
      tags                  = optional(map(string), {})
      tags_per_az           = optional(map(map(string)), {})
    }), { cidrs = [] })
    
    # Private subnets
    private = optional(object({
      cidrs                     = list(string)
      ipv6_prefixes            = optional(list(string), [])
      names                    = optional(list(string), [])
      create_nat_gateway_route = optional(bool, true)
      tags                     = optional(map(string), {})
      tags_per_az              = optional(map(map(string)), {})
    }), { cidrs = [] })
    
    # Database subnets
    database = optional(object({
      cidrs                        = list(string)
      create_subnet_group          = optional(bool, true)
      subnet_group_name            = optional(string, null)
      create_nat_gateway_route     = optional(bool, false)
      create_internet_gateway_route = optional(bool, false)
      tags                         = optional(map(string), {})
    }), { cidrs = [] })
    
    # Elasticache subnets
    elasticache = optional(object({
      cidrs                   = list(string)
      create_subnet_group     = optional(bool, true)
      subnet_group_name       = optional(string, null)
      tags                    = optional(map(string), {})
    }), { cidrs = [] })
    
    # Redshift subnets
    redshift = optional(object({
      cidrs                   = list(string)
      create_subnet_group     = optional(bool, true)
      subnet_group_name       = optional(string, null)
      enable_public           = optional(bool, false)
      tags                    = optional(map(string), {})
    }), { cidrs = [] })
    
    # Intra subnets (no internet access)
    intra = optional(object({
      cidrs = list(string)
      tags  = optional(map(string), {})
    }), { cidrs = [] })
  })
}

#===========================================#
# 3. NETWORK ACLs CONFIGURATION
#===========================================#
variable "network_acls_config" {
  description = "Network ACLs configuration for security and traffic control"
  type = object({
    # Manage default ACL
    manage_default = optional(bool, true)
    default_rules = optional(object({
      ingress = optional(list(map(string)), [])
      egress  = optional(list(map(string)), [])
    }), {})
    
    # Public subnets ACLs
    public = optional(object({
      dedicated       = optional(bool, false)
      inbound_rules   = optional(list(map(string)), [])
      outbound_rules  = optional(list(map(string)), [])
      tags            = optional(map(string), {})
    }), {})
    
    # Private subnets ACLs
    private = optional(object({
      dedicated       = optional(bool, false)
      inbound_rules   = optional(list(map(string)), [])
      outbound_rules  = optional(list(map(string)), [])
      tags            = optional(map(string), {})
    }), {})
    
    # Database ACLs
    database = optional(object({
      dedicated       = optional(bool, false)
      inbound_rules   = optional(list(map(string)), [])
      outbound_rules  = optional(list(map(string)), [])
      tags            = optional(map(string), {})
    }), {})
  })
  default = {}
}

#===========================================#
# 4. GATEWAY CONFIGURATION
#===========================================#
variable "gateway_config" {
  description = "Internet and NAT Gateway configuration"
  type = object({
    # Internet Gateway
    create_igw           = optional(bool, true)
    create_egress_only_igw = optional(bool, false)
    
    # NAT Gateway
    enable_nat_gateway   = optional(bool, false)
    single_nat_gateway   = optional(bool, false)
    one_nat_gateway_per_az = optional(bool, false)
    reuse_nat_ips        = optional(bool, false)
    external_nat_ip_ids  = optional(list(string), [])
    nat_gateway_tags     = optional(map(string), {})
    nat_eip_tags         = optional(map(string), {})
  })
  default = {
    create_igw = true
  }
}

#===========================================#
# 5. VPN CONFIGURATION
#===========================================#
variable "vpn_config" {
  description = "VPN Gateway and Customer Gateway configuration"
  type = object({
    # VPN Gateway
    enable_vpn_gateway = optional(bool, false)
    vpn_gateway_id     = optional(string, "")
    amazon_side_asn    = optional(string, "64512")
    vpn_gateway_az     = optional(string, null)
    
    # Route propagation
    propagate_private_route_tables = optional(bool, false)
    propagate_public_route_tables  = optional(bool, false)
    propagate_intra_route_tables   = optional(bool, false)
    
    # Customer Gateways
    customer_gateways = optional(map(map(any)), {})
    customer_gateway_tags = optional(map(string), {})
  })
  default = {}
}

#===========================================#
# 6. DEFAULT RESOURCES MANAGEMENT
#===========================================#
variable "default_resources_config" {
  description = "Configuration for managing default VPC resources"
  type = object({
    # Default VPC
    manage_default_vpc           = optional(bool, false)
    default_vpc_name             = optional(string, null)
    default_vpc_enable_dns_support = optional(bool, true)
    default_vpc_enable_dns_hostnames = optional(bool, true)
    
    # Default Security Group
    manage_default_security_group = optional(bool, true)
    default_security_group_name   = optional(string, null)
    default_security_group_ingress = optional(list(map(string)), [])
    default_security_group_egress  = optional(list(map(string)), [])
    
    # Default Network ACL
    manage_default_network_acl = optional(bool, true)
    
    # Default Route Table
    manage_default_route_table = optional(bool, true)
    default_route_table_routes = optional(list(map(string)), [])
  })
  default = {}
}

#===========================================#
# 7. VPC FLOW LOGS
#===========================================#
variable "flow_logs_config" {
  description = "VPC Flow Logs configuration for monitoring and compliance"
  type = object({
    enable              = optional(bool, false)
    traffic_type        = optional(string, "ALL") # ACCEPT, REJECT, ALL
    destination_type    = optional(string, "cloud-watch-logs") # s3, kinesis-data-firehose, cloud-watch-logs
    destination_arn     = optional(string, "")
    log_format          = optional(string, null)
    max_aggregation_interval = optional(number, 600)
    
    # CloudWatch specific
    cloudwatch = optional(object({
      create_log_group    = optional(bool, false)
      create_iam_role     = optional(bool, false)
      iam_role_arn        = optional(string, "")
      log_group_name_prefix = optional(string, "/aws/vpc-flow-log/")
      log_group_name_suffix = optional(string, "")
      retention_in_days   = optional(number, null)
      kms_key_id          = optional(string, null)
    }), {})
    
    # S3 specific
    s3 = optional(object({
      file_format               = optional(string, null) # plain-text, parquet
      hive_compatible_partitions = optional(bool, false)
      per_hour_partition        = optional(bool, false)
    }), {})
    
    tags = optional(map(string), {})
  })
  default = {}
}

#===========================================#
# 8. ADVANCED FEATURES
#===========================================#
variable "advanced_config" {
  description = "Advanced VPC features configuration"
  type = object({
    # DHCP Options
    enable_dhcp_options = optional(bool, false)
    dhcp_options = optional(object({
      domain_name          = optional(string, "")
      domain_name_servers  = optional(list(string), ["AmazonProvidedDNS"])
      ntp_servers          = optional(list(string), [])
      netbios_name_servers = optional(list(string), [])
      netbios_node_type    = optional(string, "")
    }), {})
    
    # VPC Block Public Access
    vpc_block_public_access_options = optional(map(string), {})
    vpc_block_public_access_exclusions = optional(map(any), {})
    
    # Network Address Usage Metrics
    enable_network_address_usage_metrics = optional(bool, null)
  })
  default = {}
}
