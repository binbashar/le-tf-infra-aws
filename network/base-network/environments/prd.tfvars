#===========================================#
# VPC Configuration for Production Account
# High availability configuration for production workloads
#===========================================#

vpc_config = {
  version = "6.5.0"
  region  = "us-east-1"

  vpc = {
    metadata = {
      name        = "prd-vpc"
      environment = "production"
      tags = {
        Environment = "production"
        Purpose     = "production"
        Backup      = "required"
      }
    }

    networking = {
      cidrBlock = "172.18.0.0/20"

      subnets = {
        public = [
          {
            name             = "public-1a"
            cidr             = "172.18.8.0/24"
            availabilityZone = "us-east-1a"
          },
          {
            name             = "public-1b"
            cidr             = "172.18.9.0/24"
            availabilityZone = "us-east-1b"
          },
          {
            name             = "public-1c"
            cidr             = "172.18.10.0/24"
            availabilityZone = "us-east-1c"
          }
        ]

        private = [
          {
            name             = "private-1a"
            cidr             = "172.18.0.0/24"
            availabilityZone = "us-east-1a"
          },
          {
            name             = "private-1b"
            cidr             = "172.18.1.0/24"
            availabilityZone = "us-east-1b"
          },
          {
            name             = "private-1c"
            cidr             = "172.18.2.0/24"
            availabilityZone = "us-east-1c"
          }
        ]

        database = [
          {
            name             = "database-1a"
            cidr             = "172.18.3.0/24"
            availabilityZone = "us-east-1a"
          },
          {
            name             = "database-1b"
            cidr             = "172.18.4.0/24"
            availabilityZone = "us-east-1b"
          },
          {
            name             = "database-1c"
            cidr             = "172.18.5.0/24"
            availabilityZone = "us-east-1c"
          }
        ]

        redshift = []

        elasticache = []

        intra = []

        outpost = []
      }

      internetGateway = {
        enabled = true
        name    = "prd-igw"
      }

      natGateways = {
        enabled = true
        single  = false # NAT Gateway per AZ (high availability)
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
        retentionDays      = 30
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
