#===========================================#
# VPC Configuration Locals
# Computed values derived from vpc_config design spec
#
# This file acts as a translation layer between the high-level `vpc_config` object
# and the specific inputs required by the AWS VPC Terraform module.
# It flattens nested structures into lists and maps.
#===========================================#
locals {
  #===========================================#
  # Subnet Configuration Extraction
  # The VPC module expects separate lists for CIDRs, names, and Availability Zones.
  # We use `for` loops to iterate over the subnet objects in `var.vpc_config`
  # and extract the specific attribute for each list.
  #===========================================#

  # Public subnets: Extract CIDR blocks, names, and availability zones
  public_subnets_cidrs = [for s in var.vpc_config.vpc.networking.subnets.public : s.cidr]
  public_subnet_names  = [for s in var.vpc_config.vpc.networking.subnets.public : s.name]
  public_subnet_azs    = [for s in var.vpc_config.vpc.networking.subnets.public : s.availabilityZone]

  # Private subnets: Extract CIDR blocks, names, and availability zones
  private_subnets_cidrs = [for s in var.vpc_config.vpc.networking.subnets.private : s.cidr]
  private_subnet_names  = [for s in var.vpc_config.vpc.networking.subnets.private : s.name]
  private_subnet_azs    = [for s in var.vpc_config.vpc.networking.subnets.private : s.availabilityZone]

  # Database subnets: Extract CIDR blocks, names, and availability zones
  database_subnets_cidrs = [for s in var.vpc_config.vpc.networking.subnets.database : s.cidr]
  database_subnet_names  = [for s in var.vpc_config.vpc.networking.subnets.database : s.name]
  database_subnet_azs    = [for s in var.vpc_config.vpc.networking.subnets.database : s.availabilityZone]

  # Redshift subnets: Extract CIDR blocks, names, and availability zones
  redshift_subnets_cidrs = [for s in var.vpc_config.vpc.networking.subnets.redshift : s.cidr]
  redshift_subnet_names  = [for s in var.vpc_config.vpc.networking.subnets.redshift : s.name]
  redshift_subnet_azs    = [for s in var.vpc_config.vpc.networking.subnets.redshift : s.availabilityZone]

  # Elasticache subnets: Extract CIDR blocks, names, and availability zones
  elasticache_subnets_cidrs = [for s in var.vpc_config.vpc.networking.subnets.elasticache : s.cidr]
  elasticache_subnet_names  = [for s in var.vpc_config.vpc.networking.subnets.elasticache : s.name]
  elasticache_subnet_azs    = [for s in var.vpc_config.vpc.networking.subnets.elasticache : s.availabilityZone]

  # Intra subnets: Extract CIDR blocks, names, and availability zones (no internet access)
  intra_subnets_cidrs = [for s in var.vpc_config.vpc.networking.subnets.intra : s.cidr]
  intra_subnet_names  = [for s in var.vpc_config.vpc.networking.subnets.intra : s.name]
  intra_subnet_azs    = [for s in var.vpc_config.vpc.networking.subnets.intra : s.availabilityZone]

  # Outpost subnets: Extract CIDR blocks, names, and availability zones (for AWS Outposts)
  outpost_subnets_cidrs = [for s in var.vpc_config.vpc.networking.subnets.outpost : s.cidr]
  outpost_subnet_names  = [for s in var.vpc_config.vpc.networking.subnets.outpost : s.name]
  outpost_subnet_azs    = [for s in var.vpc_config.vpc.networking.subnets.outpost : s.availabilityZone]

  #===========================================#
  # Subnet Tags Configuration
  # Extract tags from subnet objects and create maps for VPC module
  # The module supports both common tags (*_subnet_tags) and per-AZ tags (*_subnet_tags_per_az)
  # We use tags_per_az to support individual subnet tags
  # Note: If multiple subnets exist in the same AZ, tags will be merged
  #===========================================#

  # Public subnet tags per AZ: Map of AZ -> merged tags for all subnets in that AZ
  # We iterate over unique AZs, then find all subnets in that AZ, and merge their tags.
  # The `merge(... )` function combines the maps; if keys collide, the later one wins.
  public_subnet_tags_per_az = {
    for az in distinct([for s in var.vpc_config.vpc.networking.subnets.public : s.availabilityZone]) :
    az => merge([
      for s in var.vpc_config.vpc.networking.subnets.public :
      try(s.tags, {}) if s.availabilityZone == az
    ]...)
  }

  # Private subnet tags per AZ: Map of AZ -> merged tags for all subnets in that AZ
  private_subnet_tags_per_az = {
    for az in distinct([for s in var.vpc_config.vpc.networking.subnets.private : s.availabilityZone]) :
    az => merge([
      for s in var.vpc_config.vpc.networking.subnets.private :
      try(s.tags, {}) if s.availabilityZone == az
    ]...)
  }

  #===========================================#
  # Common Subnet Tags (for subnet types that don't support tags_per_az)
  # These are merged tags from all subnets of each type
  # Note: Only public and private subnets support tags_per_az in this module version.
  # For other types, we use common tags (merged from all subnets of that type).
  #===========================================#

  # Database subnet tags: Merge all tags from all database subnets
  # If no subnets exist, return empty map
  database_subnet_tags = length(var.vpc_config.vpc.networking.subnets.database) > 0 ? merge([
    for s in var.vpc_config.vpc.networking.subnets.database :
    try(s.tags, {})
  ]...) : {}

  # Redshift subnet tags: Merge all tags from all redshift subnets
  # If no subnets exist, return empty map
  redshift_subnet_tags = length(var.vpc_config.vpc.networking.subnets.redshift) > 0 ? merge([
    for s in var.vpc_config.vpc.networking.subnets.redshift :
    try(s.tags, {})
  ]...) : {}

  # Elasticache subnet tags: Merge all tags from all elasticache subnets
  # If no subnets exist, return empty map
  elasticache_subnet_tags = length(var.vpc_config.vpc.networking.subnets.elasticache) > 0 ? merge([
    for s in var.vpc_config.vpc.networking.subnets.elasticache :
    try(s.tags, {})
  ]...) : {}

  # Intra subnet tags: Merge all tags from all intra subnets
  # If no subnets exist, return empty map
  intra_subnet_tags = length(var.vpc_config.vpc.networking.subnets.intra) > 0 ? merge([
    for s in var.vpc_config.vpc.networking.subnets.intra :
    try(s.tags, {})
  ]...) : {}

  # Outpost subnet tags: Merge all tags from all outpost subnets
  # If no subnets exist, return empty map
  outpost_subnet_tags = length(var.vpc_config.vpc.networking.subnets.outpost) > 0 ? merge([
    for s in var.vpc_config.vpc.networking.subnets.outpost :
    try(s.tags, {})
  ]...) : {}

  #===========================================#
  # Availability Zones Aggregation
  # Combine all unique availability zones from all subnet types
  # This ensures the VPC covers all AZs used by any subnet.
  #===========================================#
  all_azs = distinct(concat(
    local.public_subnet_azs,
    local.private_subnet_azs,
    local.database_subnet_azs,
    local.redshift_subnet_azs,
    local.elasticache_subnet_azs,
    local.intra_subnet_azs,
    local.outpost_subnet_azs
  ))

  #===========================================#
  # NAT Gateway Configuration Derivation
  # Map natGateways object to module boolean flags
  #===========================================#

  # Enable NAT gateway from design spec
  enable_nat_gateway = var.vpc_config.vpc.networking.natGateways.enabled

  # Single NAT gateway mode from design spec
  # If true, only one NAT Gateway is created for the entire VPC.
  single_nat_gateway = var.vpc_config.vpc.networking.natGateways.single

  # One NAT gateway per AZ: true if enabled and not single
  # This creates a NAT Gateway in each Availability Zone for high availability.
  one_nat_gateway_per_az = var.vpc_config.vpc.networking.natGateways.enabled && !var.vpc_config.vpc.networking.natGateways.single

  # External NAT IP allocation IDs (empty list - not supported in simplified format)
  # Note: If you need to reuse existing Elastic IPs, you'll need to extend the natGateways object
  external_nat_ip_ids = []

  #===========================================#
  # VPC Flow Logs Configuration
  # Map flow logs settings from design spec to module format
  #===========================================#

  # Flow logs enabled flag from design spec
  flow_logs_enabled = var.vpc_config.vpc.monitoring.flowLogs.enabled

  # Map log destination type from design spec to module format
  # Supports: cloud-watch-logs, s3, kinesis-data-firehose
  # Defaults to cloud-watch-logs if not specified or if invalid.
  flow_log_destination_type = var.vpc_config.vpc.monitoring.flowLogs.logDestinationType == "cloud-watch-logs" ? "cloud-watch-logs" : (
    var.vpc_config.vpc.monitoring.flowLogs.logDestinationType == "s3" ? "s3" : "cloud-watch-logs"
  )
}

/*
locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  # Network Local Vars
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  vpc_name       = "${var.project}-${var.environment}-vpc"
  vpc_cidr_block = "172.20.0.0/20"
  azs = [
    "${var.region}a",
    "${var.region}b",
  ]

  private_subnets_cidr = ["172.20.0.0/21"]
  private_subnets = [
    "172.20.0.0/23",
    "172.20.2.0/23",
  ]

  public_subnets_cidr = ["172.20.8.0/21"]
  public_subnets = [
    "172.20.8.0/23",
    "172.20.10.0/23",
  ]
}

locals {
  # private inbounds
  private_inbound = flatten([
    for index, state in local.datasources-vpcs : [
      for k, v in state.outputs.private_subnets_cidr :
      {
        rule_number = 10 * (index(keys(local.datasources-vpcs), index) + 1) + 100 * k
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = state.outputs.private_subnets_cidr[k]
      }
    ]
  ])

  network_acls = {
    #
    # Allow / Deny VPC private subnets inbound default traffic
    #
    default_inbound = [
      {
        rule_number = 900 # shared pritunl vpn server
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = "${data.terraform_remote_state.tools-vpn-server.outputs.instance_private_ip}/32"
      },
      {
        rule_number = 910 # vault hvn vpc
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "all"
        cidr_block  = var.vpc_vault_hvn_cird
      },
      {
        rule_number = 920 # NTP traffic
        rule_action = "allow"
        from_port   = 123
        to_port     = 123
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 930 # Fltering known TCP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65525
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 940 # Fltering known UDP ports (0-1024)
        rule_action = "allow"
        from_port   = 1024
        to_port     = 65525
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
    ]

    #
    # Allow VPC private subnets inbound traffic
    #
    private_inbound = local.private_inbound
  }

  # Data source definitions
  #

  # shared
  shared-vpcs = {
    shared-base = {
      region  = var.region
      profile = "${var.project}-shared-devops"
      bucket  = "${var.project}-shared-terraform-backend"
      key     = "shared/network/terraform.tfstate"
    }
  }

  # network
  network-vpcs = {
    network-firewall = {
      region  = var.region
      profile = "${var.project}-network-devops"
      bucket  = "${var.project}-network-terraform-backend"
      key     = "network/network-firewall/terraform.tfstate"
    }
  }

  # apps-devstg
  apps-devstg-vpcs = {
    apps-devstg-base = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/network/terraform.tfstate"
    }
    apps-devstg-k8s-eks = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks/network/terraform.tfstate"
    }
    apps-devstg-eks-demoapps = {
      region  = var.region
      profile = "${var.project}-apps-devstg-devops"
      bucket  = "${var.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
    }
  }

  # apps-prd
  apps-prd-vpcs = {
    apps-prd-base = {
      region  = var.region
      profile = "${var.project}-apps-prd-devops"
      bucket  = "${var.project}-apps-prd-terraform-backend"
      key     = "apps-prd/network/terraform.tfstate"
    }
    #apps-prd-k8s-eks = {
    #  region  = var.region
    # profile = "${var.project}-apps-prd-devops"
    #  bucket  = "${var.project}-apps-prd-terraform-backend"
    # key     = "apps-prd/k8s-eks/network/terraform.tfstate"
    #}
  }

  datasources-vpcs = merge(
    data.terraform_remote_state.network-vpcs, # network
    #data.terraform_remote_state.shared-vpcs,  # shared
    #data.terraform_remote_state.apps-devstg-vpcs, # apps-devstg-vpcs
    data.terraform_remote_state.apps-prd-vpcs, # apps-prd-vpcs
  )
}

locals {
  cgws = { for k, v in local.customer_gateways :
    k => {
      bgp_asn    = v["bgp_asn"]
      ip_address = v["ip_address"]
    }
  }

  vpn_static_routes = flatten([for k, v in local.customer_gateways :
    [for r in lookup(v, "static_routes", []) :
      {
        cgw   = k
        route = r
      }
    ]
  ])
}
*/
