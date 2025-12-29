#===========================================#
# VPC Endpoints Configuration for DevStg Account
# Cost-optimized configuration for development/staging
#===========================================#

profile = "binbash-network-devops"

endpoints_config = {
  version = "6.5.0"
  region  = "us-east-1"

  metadata = {
    name        = "bb-apps-devstg-vpc-endpoints"
    environment = "devstg"
    tags = {
      Environment = "apps-devstg"
      Layer       = "base-endpoints"
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
        # Note: Gateway endpoints require route table IDs
        route_table_ids = []
        tags = {
          Name        = "bb-apps-devstg-s3-endpoint"
          Service     = "s3"
          Environment = "devstg"
        }
      }

      # DynamoDB Gateway Endpoint (no cost, no security groups needed)
      dynamodb = {
        service      = "dynamodb"
        service_type = "Gateway"
        # route_table_ids will be populated from VPC route tables
        route_table_ids = []
        tags = {
          Name        = "bb-apps-devstg-dynamodb-endpoint"
          Service     = "dynamodb"
          Environment = "devstg"
        }
      }
    }
  }

  security = {
    # Security Group for Interface Endpoints (if needed in future)
    security_group = {
      create      = false
      name        = null
      name_prefix = null
      description = null
      rules       = {}
      tags        = {}
    }

    # Default security group IDs to associate with all endpoints
    # Can be populated from VPC security groups
    default_security_group_ids = []
  }

  defaults = {
    create     = true
    subnet_ids = []
    tags = {
      ManagedBy = "terraform"
    }
    timeouts = {
      create = "10m"
      update = "10m"
      delete = "10m"
    }
  }
}
