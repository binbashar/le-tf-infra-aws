#===========================================#
# VPC Configuration for DevStg Account
# Cost-optimized configuration for development/staging
#===========================================#

profile = "binbash-network-devops"

vpc_config = {
  version = "6.5.0"
  region  = "us-east-1"

  vpc = {
    metadata = {
      name        = "bb-apps-devstg-vpc"
      environment = "devstg"
      tags = {
        Environment = "apps-devstg"
        Layer       = "base-network"
        Terraform   = "true"
      }
    }

    networking = {
      cidrBlock           = "172.18.32.0/20"
      mapPublicIpOnLaunch = true

      subnets = {
        public = [
          {
            name             = "bb-apps-devstg-vpc-public-us-east-1a"
            cidr             = "172.18.40.0/23"
            availabilityZone = "us-east-1a"
            # Optional: Add tags specific to this subnet
            tags = {
              "kubernetes.io/cluster/cluster-kops-1.k8s.devstg.binbash.aws" = "1"
              "kubernetes.io/role/elb"                                      = "1"
            }
          },
          {
            name             = "bb-apps-devstg-vpc-public-us-east-1b"
            cidr             = "172.18.42.0/23"
            availabilityZone = "us-east-1b"
            # Optional: Add tags specific to this subnet
            tags = {
              "kubernetes.io/cluster/cluster-kops-1.k8s.devstg.binbash.aws" = "1"
              "kubernetes.io/role/elb"                                      = "1"
            }
          },
          {
            name             = "bb-apps-devstg-vpc-public-us-east-1c"
            cidr             = "172.18.44.0/23"
            availabilityZone = "us-east-1c"
            # Optional: Add tags specific to this subnet
            tags = {
              "kubernetes.io/cluster/cluster-kops-1.k8s.devstg.binbash.aws" = "1"
              "kubernetes.io/role/elb"                                      = "1"
            }
          }
        ]

        private = [
          {
            name             = "bb-apps-devstg-vpc-private-us-east-1a"
            cidr             = "172.18.32.0/23"
            availabilityZone = "us-east-1a"
            tags = {
              "kubernetes.io/cluster/cluster-kops-1.k8s.devstg.binbash.aws" = "1"
              "kubernetes.io/role/internal-elb"                             = "1"
            }
          },
          {
            name             = "bb-apps-devstg-vpc-private-us-east-1b"
            cidr             = "172.18.34.0/23"
            availabilityZone = "us-east-1b"
            tags = {
              "kubernetes.io/cluster/cluster-kops-1.k8s.devstg.binbash.aws" = "1"
              "kubernetes.io/role/internal-elb"                             = "1"
            }
          },
          {
            name             = "bb-apps-devstg-vpc-private-us-east-1c"
            cidr             = "172.18.36.0/23"
            availabilityZone = "us-east-1c"
            tags = {
              "kubernetes.io/cluster/cluster-kops-1.k8s.devstg.binbash.aws" = "1"
              "kubernetes.io/role/internal-elb"                             = "1"
            }
          }
        ]

        database = []

        redshift = []

        elasticache = []

        intra = []

        outpost = []
      }

      internetGateway = {
        enabled = true
        name    = "devstg-igw"
      }

      natGateways = {
        enabled = false
        single  = true
      }

      dnsSettings = {
        enableDnsHostnames = true
        enableDnsSupport   = true
      }
    }

    monitoring = {
      flowLogs = {
        enabled            = false
        trafficType        = "ALL"
        logDestinationType = "cloud-watch-logs"
        retentionDays      = 7
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
      manageDefaultNetworkAcl  = false
      defaultNetworkAclIngress = []
      defaultNetworkAclEgress  = []
      defaultNetworkAclTags    = {}

      # Default Route Table management
      manageDefaultRouteTable          = false
      defaultRouteTablePropagatingVgws = []
      defaultRouteTableRoutes          = []
      defaultRouteTableTags            = {}
    }

    availability = {
      multiAz = true
    }
  }
}
