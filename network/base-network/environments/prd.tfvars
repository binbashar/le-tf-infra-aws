#===========================================#
# VPC Configuration for Production Account
# High availability configuration for production workloads
#===========================================#

# 1. VPC Core Configuration
vpc_config = {
  name    = "prd-vpc"
  cidr    = "172.18.0.0/20"
  azs     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  tags = {
    Environment = "production"
    Purpose     = "production"
    Backup      = "required"
  }
}

# 2. Subnets Configuration
subnets_config = {
  # Public subnets
  public = {
    cidrs = ["172.18.8.0/24", "172.18.9.0/24", "172.18.10.0/24"]
    tags = {
      Tier = "public"
    }
  }
  
  # Private subnets
  private = {
    cidrs = ["172.18.0.0/24", "172.18.1.0/24", "172.18.2.0/24"]
    create_nat_gateway_route = true
    tags = {
      Tier = "private"
    }
  }
  
  # Database subnets
  database = {
    cidrs = ["172.18.3.0/24", "172.18.4.0/24", "172.18.5.0/24"]
    create_subnet_group = true
    create_nat_gateway_route = false  # Databases should not have internet access
    create_internet_gateway_route = false
    tags = {
      Tier = "database"
    }
  }
  
  # Elasticache subnets
  elasticache = {
    cidrs = ["172.18.6.0/24", "172.18.7.0/24"]
    create_subnet_group = true
    tags = {
      Tier = "elasticache"
    }
  }
  
  # No redshift subnets for this production setup
  redshift = {
    cidrs = []
  }
  
  # No intra subnets for this production setup
  intra = {
    cidrs = []
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
        cidr_block  = "172.18.0.0/16"
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
        cidr_block  = "172.18.0.0/16"
      },
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_block  = "172.18.0.0/16"
      }
    ]
    outbound_rules = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = "172.18.0.0/16"
      }
    ]
  }
}

# 4. Gateway Configuration
gateway_config = {
  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true  # High availability: NAT per AZ
  nat_gateway_tags = {
    Purpose = "production"
  }
}

# 5. VPN Configuration
vpn_config = {
  enable_vpn_gateway = true
  amazon_side_asn   = "64512"
  propagate_private_route_tables = true
  propagate_public_route_tables  = true
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
    retention_in_days = 30
  }
  tags = {
    Purpose = "security-monitoring"
  }
}

# 8. Advanced Features
advanced_config = {
  enable_dhcp_options = false
  enable_network_address_usage_metrics = true
}
