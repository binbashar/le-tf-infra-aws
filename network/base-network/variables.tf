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
          public      = list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) }))
          private     = list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) }))
          database    = list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) }))
          redshift    = list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) }))
          elasticache = list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) }))
          intra       = list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) }))
          outpost     = list(object({ name = string, cidr = string, availabilityZone = string, tags = optional(map(string), {}) }))
        })
        internetGateway = object({
          enabled = bool
          name    = string
        })
        natGateways = object({
          enabled = bool
          single  = bool
        })
        dnsSettings = object({
          enableDnsHostnames = bool
          enableDnsSupport   = bool
        })
        mapPublicIpOnLaunch = optional(bool, false) # Map public IP on launch for public subnets
      })

      monitoring = object({
        flowLogs = object({
          enabled            = bool
          trafficType        = string # ALL | ACCEPT | REJECT
          logDestinationType = string # cloud-watch-logs | s3
          retentionDays      = number
        })
      })

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

      availability = object({
        multiAz = bool
      })
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
