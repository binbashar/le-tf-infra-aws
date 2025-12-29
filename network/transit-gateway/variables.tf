#===========================================#
# Transit Gateway Configuration - Design Spec
# Comprehensive design specification for AWS Transit Gateway infrastructure
#===========================================#
variable "tgw_config" {
  description = "Design spec for Transit Gateway. Populate via tfvars or parent module."

  type = object({
    # --- METADATA ---
    version          = string
    region           = string
    region_secondary = optional(string, null)

    metadata = object({
      name        = string
      environment = string
      tags        = map(string)
    })

    # --- CONNECTION ---
    connection = object({
      create          = optional(bool, true)
      existing_tgw_id = optional(string, null)
      accounts = object({
        network     = optional(bool, false)
        shared      = optional(bool, false)
        apps-devstg = optional(bool, false)
        apps-prd    = optional(bool, false)
      })
      vpc_attachments = optional(map(object({
        vpc_id                 = string
        vpc_cidr               = string
        subnet_ids             = list(string)
        subnet_route_table_ids = list(string)
        route_to               = optional(list(string), [])
        route_to_cidr_blocks   = optional(list(string), [])
        static_routes = optional(list(object({
          blackhole              = optional(bool, false)
          destination_cidr_block = string
        })), [])
        appliance_mode_support            = optional(string, "enable")
        transit_gateway_vpc_attachment_id = optional(string, null)
        transit_gateway_route_table_id    = optional(string, null)
      })), {})
    })

    # --- NETWORKING ---
    networking = object({
      route_tables = object({
        default = optional(object({
          create = optional(bool, true)
        }), {})
        inspection = optional(object({
          create = optional(bool, false)
        }), {})
        apps-devstg = optional(object({
          create = optional(bool, false)
        }), {})
        apps-prd = optional(object({
          create = optional(bool, false)
        }), {})
      })
      blackhole_routes = optional(list(string), [])
    })

    # --- SECURITY ---
    security = optional(object({
      ram_sharing = optional(object({
        enabled    = optional(bool, true)
        principals = optional(list(string), [])
        }), {
        enabled    = true
        principals = []
      })
      network_firewall = optional(object({
        enabled = optional(bool, false)
        }), {
        enabled = false
      })
      }), {
      ram_sharing = {
        enabled    = true
        principals = []
      }
      network_firewall = {
        enabled = false
      }
    })

    # --- HIGH_AVAILABILITY ---
    high_availability = optional(object({
      multi_region = optional(object({
        enabled     = optional(bool, false)
        peer_region = optional(string, null)
        }), {
        enabled     = false
        peer_region = null
      })
      }), {
      multi_region = {
        enabled     = false
        peer_region = null
      }
    })

    # --- MONITORING ---
    monitoring = optional(object({
      enabled = optional(bool, false)
      }), {
      enabled = false
    })

    # --- LOGGING ---
    logging = optional(object({
      enabled = optional(bool, false)
      }), {
      enabled = false
    })

    # --- COMPLIANCE ---
    compliance = optional(object({
      tags = optional(map(string), {})
      }), {
      tags = {}
    })

    # --- AUTOMATION ---
    automation = optional(object({
      auto_accept_attachments = optional(bool, false)
      auto_propagate_routes   = optional(bool, false)
      }), {
      auto_accept_attachments = false
      auto_propagate_routes   = false
    })
  })

  # No default — you must set var.tgw_config via tfvars or a parent module.
}

#===========================================#
# AWS Profile (optional, not in tgw_config)
#===========================================#
variable "profile" {
  description = "AWS profile to use"
  type        = string
  default     = null
}

#===========================================#
# Legacy Variables (for backward compatibility)
# These will be mapped from tgw_config in runtime.tf
#===========================================#
variable "project" {
  description = "Project name (legacy - use tgw_config.metadata.name instead)"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (legacy - use tgw_config.metadata.environment instead)"
  type        = string
  default     = null
}

variable "region" {
  description = "AWS region (legacy - use tgw_config.region instead)"
  type        = string
  default     = null
}

variable "enable_tgw" {
  description = "Enable Transit Gateway (legacy - use tgw_config.connection.create instead)"
  type        = bool
  default     = null
}

variable "enable_tgw_multi_region" {
  description = "Enable multi-region Transit Gateway (legacy - use tgw_config.high_availability.multi_region.enabled instead)"
  type        = bool
  default     = null
}

variable "tgw_cidrs" {
  description = "CIDR blocks for blackhole routes (legacy - use tgw_config.networking.blackhole_routes instead)"
  type        = map(string)
  default     = {}
}

variable "enable_network_firewall" {
  description = "Enable Network Firewall support (legacy - use tgw_config.security.network_firewall.enabled instead)"
  type        = bool
  default     = null
}
