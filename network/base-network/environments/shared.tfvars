#===========================================#
# VPC Configuration for Shared Account
# Configuration for shared services and cross-account connectivity
#===========================================#

# 1. VPC Core Configuration
vpc_config = {
  name    = "shared-vpc"
  cidr    = "172.19.0.0/20"
  azs     = ["us-east-1a", "us-east-1b"]
  tags = {
    Environment = "shared"
    Purpose     = "shared-services"
    CrossAccount = "true"
  }
}

# 2. Subnets Configuration
subnets_config = {
  # Public subnets
  public = {
    cidrs = ["172.19.8.0/23", "172.19.10.0/23"]
    tags = {
      Tier = "public"
      Purpose = "shared-services"
    }
  }
  
  # Private subnets
  private = {
    cidrs = ["172.19.0.0/23", "172.19.2.0/23"]
    create_nat_gateway_route = true
    tags = {
      Tier = "private"
      Purpose = "shared-services"
    }
  }
  
  # Database subnets for shared databases
  database = {
    cidrs = ["172.19.4.0/23", "172.19.6.0/23"]
    create_subnet_group = true
    create_nat_gateway_route = false
    create_internet_gateway_route = false
    tags = {
      Tier = "database"
      Purpose = "shared-databases"
    }
  }
  
  # No elasticache subnets for shared account
  elasticache = {
    cidrs = []
  }
  
  # No redshift subnets for shared account
  redshift = {
    cidrs = []
  }
  
  # Intra subnets for isolated shared services
  intra = {
    cidrs = ["172.19.12.0/23", "172.19.14.0/23"]
    tags = {
      Tier = "intra"
      Purpose = "isolated-services"
    }
  }
}

# 3. Network ACLs Configuration
network_acls_config = {
  manage_default = true
  
  public = {
    dedicated = true
    inbound_rules = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 120
        rule_action = "allow"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "10.0.0.0/8"  # Allow from corporate network
      }
    ]
    outbound_rules = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = "0.0.0.0/0"
      }
    ]
  }
  
  private = {
    dedicated = true
    inbound_rules = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = "172.19.0.0/16"
      },
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = "172.20.0.0/16"  # DevStg VPC
      },
      {
        rule_number = 120
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = "172.18.0.0/16"  # Production VPC
      }
    ]
    outbound_rules = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = "0.0.0.0/0"
      }
    ]
  }
  
  database = {
    dedicated = true
    inbound_rules = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "172.19.0.0/16"
      },
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_block  = "172.19.0.0/16"
      }
    ]
    outbound_rules = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = "172.19.0.0/16"
      }
    ]
  }
}

# 4. Gateway Configuration
gateway_config = {
  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization for shared services
  nat_gateway_tags = {
    Purpose = "shared-services"
  }
}

# 5. VPN Configuration
vpn_config = {
  enable_vpn_gateway = true
  amazon_side_asn   = "64512"
  propagate_private_route_tables = true
  propagate_public_route_tables  = true
  propagate_intra_route_tables   = true
}

# 6. Default Resources Management
default_resources_config = {
  manage_default_security_group = true
  manage_default_network_acl    = true
  manage_default_route_table   = true
  default_security_group_ingress = []
  default_security_group_egress  = []
}

# 7. VPC Flow Logs
flow_logs_config = {
  enable = true
  traffic_type = "ALL"
  destination_type = "cloud-watch-logs"
  cloudwatch = {
    create_log_group = true
    create_iam_role  = true
    retention_in_days = 90  # Longer retention for shared services
  }
  tags = {
    Purpose = "shared-services-monitoring"
  }
}

# 8. Advanced Features
advanced_config = {
  enable_dhcp_options = false
  enable_network_address_usage_metrics = true
}
