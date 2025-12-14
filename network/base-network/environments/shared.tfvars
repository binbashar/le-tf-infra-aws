#===========================================#
# VPC Configuration for Shared Account
# Configuration for shared services and cross-account connectivity
#===========================================#

vpc_config = {
  version = "6.5.0"
  region  = "us-east-1"

  vpc = {
    metadata = {
      name        = "shared-vpc"
      environment = "shared"
      tags = {
        Environment  = "shared"
        Purpose      = "shared-services"
        CrossAccount = "true"
      }
    }

    networking = {
      cidrBlock = "172.19.0.0/20"

      subnets = {
        public = [
          {
            name             = "public-1a"
            cidr             = "172.19.8.0/23"
            availabilityZone = "us-east-1a"
          },
          {
            name             = "public-1b"
            cidr             = "172.19.10.0/23"
            availabilityZone = "us-east-1b"
          }
        ]

        private = [
          {
            name             = "private-1a"
            cidr             = "172.19.0.0/23"
            availabilityZone = "us-east-1a"
          },
          {
            name             = "private-1b"
            cidr             = "172.19.2.0/23"
            availabilityZone = "us-east-1b"
          }
        ]

        database = [
          {
            name             = "database-1a"
            cidr             = "172.19.4.0/23"
            availabilityZone = "us-east-1a"
          },
          {
            name             = "database-1b"
            cidr             = "172.19.6.0/23"
            availabilityZone = "us-east-1b"
          }
        ]

        redshift = []

        elasticache = []

        intra = []

        outpost = []
      }

      internetGateway = {
        enabled = true
        name    = "shared-igw"
      }

      natGateways = {
        enabled = true
        single  = true
      }

      dnsSettings = {
        enableDnsHostnames = true
        enableDnsSupport   = true
      }
    }

    monitoring = {
      flowLogs = {
        enabled            = true
        trafficType        = "ALL"
        logDestinationType = "cloud-watch-logs"
        retentionDays      = 90
      }
    }

    defaultResources = {
      # Default VPC management
      manageDefaultVpc             = false
      defaultVpcEnableDnsSupport   = true
      defaultVpcEnableDnsHostnames = true
      defaultVpcTags               = {}

      # Default Security Group management
      manageDefaultSecurityGroup  = true
      defaultSecurityGroupIngress = []
      defaultSecurityGroupEgress  = []
      defaultSecurityGroupTags    = {}

      # Default Network ACL management
      manageDefaultNetworkAcl  = true
      defaultNetworkAclIngress = []
      defaultNetworkAclEgress  = []
      defaultNetworkAclTags    = {}

      # Default Route Table management
      manageDefaultRouteTable          = true
      defaultRouteTablePropagatingVgws = []
      defaultRouteTableRoutes          = []
      defaultRouteTableTags            = {}
    }

    availability = {
      multiAz = true
    }
  }
}
