#===========================================#
# VPC Configuration for DevStg Account
# Cost-optimized configuration for development/staging
#===========================================#

# 0. Basic
region = "us-east-1"
profile = "binbash-network-devops"
project = "binbash"
environment = "devstg"
layer_name = "base-network"

# 1. VPC Core Configuration
vpc_config = {
  name    = "devstg-vpc"
  cidr    = "172.20.0.0/20"
  azs     = ["us-east-1a", "us-east-1b"]
  tags = {
    Environment = "devstg"
    Purpose     = "development"
  }
}

# 2. Subnets Configuration
subnets_config = {
  # Public subnets
  public = {
    cidrs = ["172.20.8.0/23", "172.20.10.0/23"]
    tags = {
      Tier = "public"
    }
  }
  
  # Private subnets
  private = {
    cidrs = ["172.20.0.0/23", "172.20.2.0/23"]
    create_nat_gateway_route = true
    tags = {
      Tier = "private"
    }
  }
  
  # No database subnets for devstg (cost optimization)
  database = {
    cidrs = []
  }
  
  # No elasticache subnets for devstg
  elasticache = {
    cidrs = []
  }
  
  # No redshift subnets for devstg
  redshift = {
    cidrs = []
  }
  
  # No intra subnets for devstg
  intra = {
    cidrs = []
  }
}

# 3. Network ACLs Configuration
network_acls_config = {
  manage_default = true
  
  public = {
    dedicated = false  # Use default ACL for cost savings
  }
  
  private = {
    dedicated = false  # Use default ACL for cost savings
  }
}

# 4. Gateway Configuration
gateway_config = {
  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization: single NAT for all AZs
}

# 5. VPN Configuration
vpn_config = {
  enable_vpn_gateway = false  # No VPN needed for devstg
}

# 6. Default Resources Management
default_resources_config = {
  manage_default_security_group = true
  manage_default_network_acl    = true
  manage_default_route_table   = true
}

# 7. VPC Flow Logs
flow_logs_config = {
  enable = false  # Disabled for cost savings in devstg
}

# 8. Advanced Features
advanced_config = {
  enable_dhcp_options = false
}
