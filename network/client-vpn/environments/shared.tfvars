#===========================================#
# Client VPN Configuration - Shared Environment
#===========================================#

client_vpn_config = {
  version = "1.0.0"
  region  = "us-east-1"

  metadata = {
    name        = "bb-network-client-vpn"
    environment = "shared"
    tags = {
      Environment = "network"
      Layer       = "client-vpn"
      Terraform   = "true"
    }
  }

  connection = {
    vpc_id     = null # Will be looked up from remote state
    subnet_ids = []   # Will be populated from remote state or provided directly
  }

  networking = {
    client_cidr_block  = "172.16.0.0/16"
    split_tunnel       = true
    dns_servers        = []
    transport_protocol = "udp"
    routes             = []
  }

  security = {
    server_certificate_arn = "" # Replace with actual ARN

    security_group = {
      create      = true
      name        = null
      description = "Security group for Client VPN endpoint"
      rules = {
        egress = [
          {
            rule        = "all-all"
            cidr_blocks = "0.0.0.0/0"
          }
        ]
      }
      tags = {}
    }

    authentication = {
      type              = "federated-authentication"
      saml_provider_arn = null
    }

    authorization_rules = []
  }

  logging = {
    connection_logs = {
      enabled              = true
      cloudwatch_log_group = null
      retention_in_days    = 60
      kms_key_id           = null
    }
  }

  compliance = {
    saml_provider = {
      name               = "bb-network-client-vpn"
      saml_metadata_path = "saml-metadata.xml"
    }

    sso_groups = {
      devops = {
        group_name        = "DevOps"
        identity_store_id = null
      }
    }
  }

  high_availability = {
    multi_az = true
  }
}

profile = null
bucket  = null

