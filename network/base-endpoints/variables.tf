#===========================================#
# VPC Endpoints Configuration - Design Spec
# Comprehensive design specification for VPC Endpoints infrastructure
#===========================================#
variable "endpoints_config" {
  description = "Design spec for VPC Endpoints. Populate via tfvars or parent module."

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
      vpc_id = optional(string, null) # VPC ID (can be null if using data source)
    })

    # --- NETWORKING ---
    networking = object({
      endpoints = map(object({
        # Service identification (one of these required)
        service          = optional(string, null)
        service_name     = optional(string, null)
        service_endpoint = optional(string, null)

        # Endpoint type and region
        service_type   = optional(string, "Interface") # Interface | Gateway
        service_region = optional(string, null)

        # Endpoint-specific configuration
        create              = optional(bool, true)
        auto_accept         = optional(bool, null)
        policy              = optional(string, null)
        private_dns_enabled = optional(bool, null)   # Interface only
        ip_address_type     = optional(string, null) # Interface only

        # Network configuration
        subnet_ids         = optional(list(string), [])
        security_group_ids = optional(list(string), [])
        route_table_ids    = optional(list(string), []) # Gateway only

        # Advanced DNS configuration
        dns_options = optional(object({
          dns_record_ip_type                             = optional(string, null)
          private_dns_only_for_inbound_resolver_endpoint = optional(bool, null)
        }), null)

        # Subnet IP configuration
        subnet_configurations = optional(list(object({
          ipv4      = optional(string, null)
          ipv6      = optional(string, null)
          subnet_id = string
        })), [])

        tags = optional(map(string), {})
      }))
    })

    # --- SECURITY ---
    security = optional(object({
      security_group = optional(object({
        create      = optional(bool, false)
        name        = optional(string, null)
        name_prefix = optional(string, null)
        description = optional(string, null)
        rules = optional(map(object({
          type                     = optional(string, "ingress")
          protocol                 = optional(string, "tcp")
          from_port                = optional(number, 443)
          to_port                  = optional(number, 443)
          description              = optional(string, null)
          cidr_blocks              = optional(list(string), null)
          ipv6_cidr_blocks         = optional(list(string), null)
          prefix_list_ids          = optional(list(string), null)
          self                     = optional(bool, null)
          source_security_group_id = optional(string, null)
        })), {})
        tags = optional(map(string), {})
        }), {
        create      = false
        name        = null
        name_prefix = null
        description = null
        rules       = {}
        tags        = {}
      })

      # Default security group IDs for all endpoints
      default_security_group_ids = optional(list(string), [])
      }), {
      security_group = {
        create      = false
        name        = null
        name_prefix = null
        description = null
        rules       = {}
        tags        = {}
      }
      default_security_group_ids = []
    })

    # --- DEFAULTS ---
    # Default values applied to all endpoints (subnet IDs, tags, timeouts, create flag)
    defaults = optional(object({
      create     = optional(bool, true)
      subnet_ids = optional(list(string), [])
      tags       = optional(map(string), {})
      timeouts = optional(object({
        create = optional(string, "10m")
        update = optional(string, "10m")
        delete = optional(string, "10m")
        }), {
        create = "10m"
        update = "10m"
        delete = "10m"
      })
      }), {
      create     = true
      subnet_ids = []
      tags       = {}
      timeouts = {
        create = "10m"
        update = "10m"
        delete = "10m"
      }
    })
  })

  # No default — you must set var.endpoints_config via tfvars or a parent module.
}

#===========================================#
# AWS Profile (optional, not in endpoints_config)
#===========================================#
variable "profile" {
  description = "AWS profile to use"
  type        = string
  default     = null
}
