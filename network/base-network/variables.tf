#===========================================#
# VPC Configuration - Design Spec
# Comprehensive design specification for VPC infrastructure
#===========================================#
variable "vpc_config" {
  description = "Design spec for the VPC. Populate via tfvars or parent module."

  type = object({
    version = string
    region  = string

    vpc = object({
      metadata = object({
        name        = string
        environment = string
        tags        = map(string)
      })

      networking = object({
        cidrBlock = string
        subnets = object({
          public      = optional(list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) })), [])
          private     = optional(list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) })), [])
          database    = optional(list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) })), [])
          redshift    = optional(list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) })), [])
          elasticache = optional(list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) })), [])
          intra       = optional(list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) })), [])
          outpost     = optional(list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) })), [])
        })
        internetGateway = optional(object({
          enabled = bool
          name    = optional(string, null)
        }), { enabled = true, name = null })
        natGateways = optional(object({
          enabled = bool
          single  = bool
        }), { enabled = true, single = true })
        dnsSettings = optional(object({
          enableDnsHostnames = bool
          enableDnsSupport   = bool
        }), { enableDnsHostnames = true, enableDnsSupport = true })
        mapPublicIpOnLaunch = optional(bool, false) # Map public IP on launch for public subnets
      })

      monitoring = optional(object({
        flowLogs = optional(object({
          enabled            = bool
          trafficType        = optional(string, "ALL")
          logDestinationType = optional(string, "cloud-watch-logs")
          retentionDays      = optional(number, 7)
        }), { enabled = false, trafficType = "ALL", logDestinationType = "cloud-watch-logs", retentionDays = 7 })
      }), { flowLogs = { enabled = false, trafficType = "ALL", logDestinationType = "cloud-watch-logs", retentionDays = 7 } })

      defaultResources = optional(object({
        # Default VPC management
        manageDefaultVpc             = optional(bool, false)
        defaultVpcName               = optional(string, null)
        defaultVpcEnableDnsSupport   = optional(bool, true)
        defaultVpcEnableDnsHostnames = optional(bool, true)
        defaultVpcTags               = optional(map(string), {})

        # Default Security Group management
        manageDefaultSecurityGroup = optional(bool, true)
        defaultSecurityGroupName   = optional(string, null)
        # Ingress/egress rules: list of maps with keys: from_port, to_port, protocol, cidr_blocks, description, etc.
        defaultSecurityGroupIngress = optional(list(map(string)), [])
        defaultSecurityGroupEgress  = optional(list(map(string)), [])
        defaultSecurityGroupTags    = optional(map(string), {})

        # Default Network ACL management
        manageDefaultNetworkAcl = optional(bool, true)
        defaultNetworkAclName   = optional(string, null)
        # ACL rules: list of maps with keys: rule_no, action, from_port, to_port, protocol, cidr_block, ipv6_cidr_block
        defaultNetworkAclIngress = optional(list(map(string)), [])
        defaultNetworkAclEgress  = optional(list(map(string)), [])
        defaultNetworkAclTags    = optional(map(string), {})

        # Default Route Table management
        manageDefaultRouteTable          = optional(bool, true)
        defaultRouteTableName            = optional(string, null)
        defaultRouteTablePropagatingVgws = optional(list(string), [])
        # Routes: list of maps with keys: cidr_block, gateway_id, nat_gateway_id, etc.
        defaultRouteTableRoutes = optional(list(map(string)), [])
        defaultRouteTableTags   = optional(map(string), {})
        }), {
        # Default values when defaultResources is not provided
        manageDefaultVpc                 = false
        defaultVpcName                   = null
        defaultVpcEnableDnsSupport       = true
        defaultVpcEnableDnsHostnames     = true
        defaultVpcTags                   = {}
        manageDefaultSecurityGroup       = true
        defaultSecurityGroupName         = null
        defaultSecurityGroupIngress      = []
        defaultSecurityGroupEgress       = []
        defaultSecurityGroupTags         = {}
        manageDefaultNetworkAcl          = true
        defaultNetworkAclName            = null
        defaultNetworkAclIngress         = []
        defaultNetworkAclEgress          = []
        defaultNetworkAclTags            = {}
        manageDefaultRouteTable          = true
        defaultRouteTableName            = null
        defaultRouteTablePropagatingVgws = []
        defaultRouteTableRoutes          = []
        defaultRouteTableTags            = {}
      })

      availability = optional(object({
        multiAz = bool
      }), { multiAz = true })
    })
  })

  # No default — you must set var.vpc_config via tfvars or a parent module.
}

#===========================================#
# AWS Profile (optional, not in vpc_config)
#===========================================#
variable "profile" {
  description = "AWS profile to use"
  type        = string
  default     = null
}
