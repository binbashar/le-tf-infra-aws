#===========================================#
# Client VPN Configuration - DevStg Environment
#===========================================#

client_vpn_config = {
  version = "1.0.0"
  region  = "us-east-1"

  metadata = {
    name        = "bb-apps-devstg-client-vpn"
    environment = "devstg"
    tags = {
      Environment = "apps-devstg"
      Layer       = "client-vpn"
      Terraform   = "true"
    }
  }

  connection = {
    # VPC ID can be null if using remote state data sources
    # Otherwise, provide the VPC ID directly
    vpc_id     = null # Will be looked up from remote state
    subnet_ids = []   # Will be populated from remote state or provided directly
  }

  networking = {
    client_cidr_block  = "172.16.0.0/16"
    split_tunnel       = true
    dns_servers        = [] # Will be computed from VPC CIDR if using remote state
    transport_protocol = "udp"
    routes             = [] # Will be auto-generated from authorization_rules if empty
  }

  security = {
    # Server certificate ARN from remote state (data.terraform_remote_state.certs)
    server_certificate_arn = "" # Replace with actual ARN or use data source

    security_group = {
      create      = true
      name        = null # Will default to "${vpn_name}-sg"
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
      saml_provider_arn = null # Will use created SAML provider if compliance.saml_provider is configured
    }

    authorization_rules = [
      # Example: Allow access to network VPCs
      # {
      #   target_network_cidr = "10.0.0.0/16"
      #   access_group_id      = null # Will use SSO group from compliance.sso_groups
      #   authorize_all_groups = false
      #   description          = "Authorization for devops to network VPC"
      # }
    ]
  }

  logging = {
    connection_logs = {
      enabled              = true
      cloudwatch_log_group = null # Will default to "${vpn_name}-logs"
      retention_in_days    = 60
      kms_key_id           = null # Will use KMS key from remote state if available
    }
  }

  compliance = {
    saml_provider = {
      name               = "bb-apps-devstg-client-vpn"
      saml_metadata_path = "saml-metadata.xml"
    }

    sso_groups = {
      devops = {
        group_name        = "DevOps"
        identity_store_id = null # Will be looked up automatically
      }
    }
  }

  high_availability = {
    multi_az = true
  }
}

# Optional: AWS profile and backend bucket for remote state data sources
profile = null
bucket  = null

