#===========================================#
# VPC Endpoints Configuration for Production Account
# High availability configuration for production workloads
#===========================================

endpoints_config = {
  version = "6.5.0"
  region  = "us-east-1"

  metadata = {
    name        = "prd-vpc-endpoints"
    environment = "production"
    tags = {
      Environment = "production"
      Purpose     = "production"
      Backup      = "required"
      Terraform   = "true"
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
          Name        = "prd-s3-endpoint"
          Service     = "s3"
          Environment = "production"
        }
      }

      # DynamoDB Gateway Endpoint (no cost, no security groups needed)
      dynamodb = {
        service      = "dynamodb"
        service_type = "Gateway"
        # route_table_ids will be populated from VPC route tables
        route_table_ids = []
        tags = {
          Name        = "prd-dynamodb-endpoint"
          Service     = "dynamodb"
          Environment = "production"
        }
      }

      # KMS Interface Endpoint (for encryption key management)
      kms = {
        service             = "kms"
        service_type        = "Interface"
        private_dns_enabled = true
        # subnet_ids will be populated from VPC private subnets
        subnet_ids = []
        # security_group_ids will be populated from security.default_security_group_ids or endpoint-specific
        security_group_ids = []
        tags = {
          Name        = "prd-kms-endpoint"
          Service     = "kms"
          Environment = "production"
        }
      }

      # SSM Interface Endpoint (for Systems Manager)
      ssm = {
        service             = "ssm"
        service_type        = "Interface"
        private_dns_enabled = true
        subnet_ids          = []
        security_group_ids  = []
        tags = {
          Name        = "prd-ssm-endpoint"
          Service     = "ssm"
          Environment = "production"
        }
      }

      # EC2 Messages Interface Endpoint (for EC2 instance communication)
      ec2messages = {
        service             = "ec2messages"
        service_type        = "Interface"
        private_dns_enabled = true
        subnet_ids          = []
        security_group_ids  = []
        tags = {
          Name        = "prd-ec2messages-endpoint"
          Service     = "ec2messages"
          Environment = "production"
        }
      }

      # SSM Messages Interface Endpoint (for SSM agent communication)
      ssmmessages = {
        service             = "ssmmessages"
        service_type        = "Interface"
        private_dns_enabled = true
        subnet_ids          = []
        security_group_ids  = []
        tags = {
          Name        = "prd-ssmmessages-endpoint"
          Service     = "ssmmessages"
          Environment = "production"
        }
      }
    }
  }

  security = {
    # Security Group for Interface Endpoints
    security_group = {
      create      = true
      name        = "prd-vpc-endpoints-sg"
      name_prefix = null
      description = "Security group for VPC Interface Endpoints in production"
      rules = {
        # Allow HTTPS from VPC CIDR
        https_from_vpc = {
          type        = "ingress"
          protocol    = "tcp"
          from_port   = 443
          to_port     = 443
          description = "Allow HTTPS from VPC"
          cidr_blocks = ["172.18.0.0/20"] # Update with actual VPC CIDR
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
        Name        = "prd-vpc-endpoints-sg"
        Environment = "production"
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
      ManagedBy = "terraform"
      Backup    = "required"
    }
    timeouts = {
      create = "10m"
      update = "10m"
      delete = "10m"
    }
  }
}
