#===========================================#
# Client VPN Configuration - Design Spec
# Comprehensive design specification for AWS Client VPN infrastructure
#===========================================#
variable "client_vpn_config" {
  description = "Design spec for Client VPN. Populate via tfvars or parent module."

  type = object({
    # --- METADATA ---
    version = string
    region  = string

    metadata = object({
      name        = string
      environment = string
      tags        = map(string)
    })

    # --- CONNECTION ---
    connection = object({
      vpc_id     = optional(string, null) # VPC ID (can be null if using data source)
      subnet_ids = list(string)           # Subnet IDs for network associations
    })

    # --- NETWORKING ---
    networking = object({
      client_cidr_block  = string
      split_tunnel       = optional(bool, true)
      dns_servers        = optional(list(string), [])
      transport_protocol = optional(string, "udp") # udp | tcp
      routes = optional(list(object({
        destination_cidr_block = string
        target_subnet_id       = string
        description            = optional(string, null)
      })), [])
    })

    # --- SECURITY ---
    security = object({
      server_certificate_arn = string
      security_group = optional(object({
        create      = optional(bool, true)
        name        = optional(string, null)
        description = optional(string, null)
        rules = optional(object({
          egress = optional(list(object({
            rule        = string
            cidr_blocks = string
          })), [])
        }), {})
        tags = optional(map(string), {})
        }), {
        create      = true
        name        = null
        description = null
        rules       = {}
        tags        = {}
      })
      authentication = object({
        type                       = string # federated-authentication | certificate-authentication
        saml_provider_arn          = optional(string, null)
        root_certificate_chain_arn = optional(string, null)
      })
      authorization_rules = optional(list(object({
        target_network_cidr  = string
        access_group_id      = optional(string, null)
        authorize_all_groups = optional(bool, false)
        description          = optional(string, null)
      })), [])
    })

    # --- LOGGING ---
    logging = optional(object({
      connection_logs = optional(object({
        enabled              = optional(bool, true)
        cloudwatch_log_group = optional(string, null)
        retention_in_days    = optional(number, 60)
        kms_key_id           = optional(string, null)
        }), {
        enabled           = true
        retention_in_days = 60
      })
      }), {
      connection_logs = {
        enabled           = true
        retention_in_days = 60
      }
    })

    # --- COMPLIANCE ---
    compliance = optional(object({
      saml_provider = optional(object({
        name               = optional(string, null)
        saml_metadata_path = optional(string, null)
        }), {
        name               = null
        saml_metadata_path = null
      })
      sso_groups = optional(map(object({
        group_name        = string
        identity_store_id = optional(string, null)
      })), {})
      }), {
      saml_provider = {
        name               = null
        saml_metadata_path = null
      }
      sso_groups = {}
    })

    # --- HIGH_AVAILABILITY ---
    high_availability = optional(object({
      multi_az = optional(bool, true)
      }), {
      multi_az = true
    })
  })

  # No default — you must set var.client_vpn_config via tfvars or a parent module.
}

#===========================================#
# AWS Profile and Backend (optional, not in client_vpn_config)
#===========================================#
variable "profile" {
  description = "AWS profile to use"
  type        = string
  default     = null
}

variable "bucket" {
  description = "S3 bucket for remote state data sources"
  type        = string
  default     = null
}

