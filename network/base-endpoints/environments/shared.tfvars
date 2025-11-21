#===========================================#
# VPC Endpoints Configuration for Shared Account
# Configuration for shared services and cross-account connectivity
#===========================================

endpoints_config = {
  version = "6.5.0"
  region  = "us-east-1"

  metadata = {
    name        = "shared-vpc-endpoints"
    environment = "shared"
    tags = {
      Environment  = "shared"
      Purpose      = "shared-services"
      CrossAccount = "true"
      Terraform    = "true"
    }
  }

  connection = {
    # VPC ID - set to null if using data source to look up VPC
    # Example: vpc_id = data.aws_vpc.main.id
    vpc_id = null
  }

  networking = {
    endpoints = {
      # S3 Gateway Endpoint (no cost, no security groups needed)
      s3 = {
        service      = "s3"
        service_type = "Gateway"
        # route_table_ids will be populated from VPC route tables
        route_table_ids = []
        tags = {
          Name        = "shared-s3-endpoint"
          Service     = "s3"
          Environment = "shared"
        }
      }

      # DynamoDB Gateway Endpoint (no cost, no security groups needed)
      dynamodb = {
        service      = "dynamodb"
        service_type = "Gateway"
        # route_table_ids will be populated from VPC route tables
        route_table_ids = []
        tags = {
          Name        = "shared-dynamodb-endpoint"
          Service     = "dynamodb"
          Environment = "shared"
        }
      }

      # KMS Interface Endpoint (for encryption key management across accounts)
      kms = {
        service             = "kms"
        service_type        = "Interface"
        private_dns_enabled = true
        # subnet_ids will be populated from VPC private subnets
        subnet_ids = []
        # security_group_ids will be populated from security.default_security_group_ids or endpoint-specific
        security_group_ids = []
        tags = {
          Name         = "shared-kms-endpoint"
          Service      = "kms"
          Environment  = "shared"
          CrossAccount = "true"
        }
      }
    }
  }

  security = {
    # Security Group for Interface Endpoints (cross-account access)
    security_group = {
      create      = true
      name        = "shared-vpc-endpoints-sg"
      name_prefix = null
      description = "Security group for VPC Interface Endpoints in shared account"
      rules = {
        # Allow HTTPS from VPC CIDR
        https_from_vpc = {
          type        = "ingress"
          protocol    = "tcp"
          from_port   = 443
          to_port     = 443
          description = "Allow HTTPS from VPC"
          cidr_blocks = ["172.19.0.0/20"] # Update with actual VPC CIDR
        }
        # Allow HTTPS from trusted accounts (example CIDRs)
        https_from_trusted = {
          type        = "ingress"
          protocol    = "tcp"
          from_port   = 443
          to_port     = 443
          description = "Allow HTTPS from trusted accounts"
          cidr_blocks = [] # Add trusted account VPC CIDRs if needed
        }
        # Allow all outbound
        all_outbound = {
          type        = "egress"
          protocol    = "-1"
          from_port   = 0
          to_port     = 65535
          description = "Allow all outbound traffic"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
      tags = {
        Name         = "shared-vpc-endpoints-sg"
        Environment  = "shared"
        CrossAccount = "true"
      }
    }

    # Default security group IDs to associate with all endpoints
    # Can be populated from VPC security groups or the created security group above
    default_security_group_ids = []
  }

  defaults = {
    create     = true
    subnet_ids = []
    tags = {
      ManagedBy    = "terraform"
      CrossAccount = "true"
    }
    timeouts = {
      create = "10m"
      update = "10m"
      delete = "10m"
    }
  }
}
